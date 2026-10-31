// SPDX-License-Identifier: MIT

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <drm.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/prctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <unistd.h>
#include <xf86drm.h>
#include <xf86drmMode.h>

#define MAX_SHARED_FDS 8
#define MAX_SAVED_PLANES 16

struct shared_drm_fd {
  int fd;
  int dropped;
};

struct saved_plane {
  uint32_t plane_id;
  uint32_t crtc_id;
  uint32_t fb_id;
  int32_t crtc_x;
  int32_t crtc_y;
  uint32_t crtc_w;
  uint32_t crtc_h;
  uint32_t src_x;
  uint32_t src_y;
  uint32_t src_w;
  uint32_t src_h;
};

struct saved_output {
  uint32_t connector_id;
  uint32_t crtc_id;
  uint32_t fb_id;
  uint32_t x;
  uint32_t y;
  drmModeModeInfo mode;
  int valid;
};

struct saved_display {
  struct saved_output output;
  struct saved_plane planes[MAX_SAVED_PLANES];
  size_t plane_count;
  int valid;
  int master_index;
};

static volatile sig_atomic_t caught_signal;

static void catch_signal(int signal_number) { caught_signal = signal_number; }

static int make_directory(const char *path) {
  return mkdir(path, 0755) == 0 || errno == EEXIST;
}

static int receive_shared_fd(int channel) {
  char byte;
  struct iovec iov;
  struct msghdr message;
  char control[CMSG_SPACE(sizeof(int))];
  struct cmsghdr *header;
  ssize_t received;
  int fd = -1;

  memset(&message, 0, sizeof(message));
  memset(control, 0, sizeof(control));
  iov.iov_base = &byte;
  iov.iov_len = 1;
  message.msg_iov = &iov;
  message.msg_iovlen = 1;
  message.msg_control = control;
  message.msg_controllen = sizeof(control);
  received = recvmsg(channel, &message, 0);
  if (received <= 0) {
    return -1;
  }
  for (header = CMSG_FIRSTHDR(&message); header;
       header = CMSG_NXTHDR(&message, header)) {
    if (header->cmsg_level == SOL_SOCKET && header->cmsg_type == SCM_RIGHTS &&
        header->cmsg_len >= CMSG_LEN(sizeof(int))) {
      memcpy(&fd, CMSG_DATA(header), sizeof(fd));
      break;
    }
  }
  return fd;
}

static int plane_property_value(int fd, uint32_t plane_id, const char *name,
                                uint64_t *value_out) {
  drmModeObjectProperties *properties;
  uint32_t index;
  int found = 0;

  properties = drmModeObjectGetProperties(fd, plane_id,
                                          DRM_MODE_OBJECT_PLANE);
  if (!properties) {
    return 0;
  }
  for (index = 0; index < properties->count_props; index++) {
    drmModePropertyRes *property =
        drmModeGetProperty(fd, properties->props[index]);
    if (!property) {
      continue;
    }
    if (strcmp(property->name, name) == 0) {
      *value_out = properties->prop_values[index];
      found = 1;
      drmModeFreeProperty(property);
      break;
    }
    drmModeFreeProperty(property);
  }
  drmModeFreeObjectProperties(properties);
  return found;
}

static int snapshot_plane_geometry(int fd, struct saved_plane *plane) {
  uint64_t value;

#define READ_PLANE_PROPERTY(name, member, cast)                                \
  do {                                                                         \
    if (!plane_property_value(fd, plane->plane_id, name, &value)) {            \
      return 0;                                                                \
    }                                                                          \
    plane->member = (cast)value;                                               \
  } while (0)

  READ_PLANE_PROPERTY("CRTC_X", crtc_x, int32_t);
  READ_PLANE_PROPERTY("CRTC_Y", crtc_y, int32_t);
  READ_PLANE_PROPERTY("CRTC_W", crtc_w, uint32_t);
  READ_PLANE_PROPERTY("CRTC_H", crtc_h, uint32_t);
  READ_PLANE_PROPERTY("SRC_X", src_x, uint32_t);
  READ_PLANE_PROPERTY("SRC_Y", src_y, uint32_t);
  READ_PLANE_PROPERTY("SRC_W", src_w, uint32_t);
  READ_PLANE_PROPERTY("SRC_H", src_h, uint32_t);
#undef READ_PLANE_PROPERTY
  return plane->crtc_w && plane->crtc_h && plane->src_w && plane->src_h;
}

static int snapshot_output(int fd, struct saved_output *output) {
  drmModeRes *resources = NULL;
  drmModeConnector *connector = NULL;
  drmModeEncoder *encoder = NULL;
  drmModeCrtc *crtc = NULL;
  drmModePlaneRes *planes = NULL;
  uint32_t fallback_fb = 0;
  int index;

  memset(output, 0, sizeof(*output));
  resources = drmModeGetResources(fd);
  if (!resources) {
    return 0;
  }
  for (index = 0; index < resources->count_connectors; index++) {
    drmModeConnector *candidate =
        drmModeGetConnector(fd, resources->connectors[index]);
    if (!candidate) {
      continue;
    }
    if (candidate->connection == DRM_MODE_CONNECTED &&
        candidate->count_modes > 0 &&
        (candidate->connector_type == DRM_MODE_CONNECTOR_DSI || !connector)) {
      if (connector) {
        drmModeFreeConnector(connector);
      }
      connector = candidate;
      if (candidate->connector_type == DRM_MODE_CONNECTOR_DSI) {
        break;
      }
    } else {
      drmModeFreeConnector(candidate);
    }
  }
  if (!connector) {
    goto out;
  }
  if (connector->encoder_id) {
    encoder = drmModeGetEncoder(fd, connector->encoder_id);
  }
  if (!encoder || !encoder->crtc_id) {
    int encoder_index;
    if (encoder) {
      drmModeFreeEncoder(encoder);
      encoder = NULL;
    }
    for (encoder_index = 0; encoder_index < connector->count_encoders;
         encoder_index++) {
      drmModeEncoder *candidate =
          drmModeGetEncoder(fd, connector->encoders[encoder_index]);
      if (candidate && candidate->crtc_id) {
        encoder = candidate;
        break;
      }
      if (candidate) {
        drmModeFreeEncoder(candidate);
      }
    }
  }
  if (!encoder || !encoder->crtc_id) {
    goto out;
  }
  crtc = drmModeGetCrtc(fd, encoder->crtc_id);
  if (!crtc || !crtc->mode_valid) {
    goto out;
  }
  output->connector_id = connector->connector_id;
  output->crtc_id = crtc->crtc_id;
  output->fb_id = crtc->buffer_id;
  output->x = crtc->x;
  output->y = crtc->y;
  output->mode = crtc->mode;
  (void)drmSetClientCap(fd, DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1);
  planes = drmModeGetPlaneResources(fd);
  if (planes) {
    uint32_t plane_index;
    for (plane_index = 0; plane_index < planes->count_planes; plane_index++) {
      drmModePlane *plane = drmModeGetPlane(fd, planes->planes[plane_index]);
      uint64_t type = UINT64_MAX;
      if (!plane) {
        continue;
      }
      if (plane->crtc_id == output->crtc_id && plane->fb_id) {
        if (!fallback_fb) {
          fallback_fb = plane->fb_id;
        }
        if (plane_property_value(fd, plane->plane_id, "type", &type) &&
            type == DRM_PLANE_TYPE_PRIMARY) {
          output->fb_id = plane->fb_id;
          drmModeFreePlane(plane);
          break;
        }
      }
      drmModeFreePlane(plane);
    }
  }
  if (!output->fb_id) {
    output->fb_id = fallback_fb;
  }
  output->valid = output->fb_id != 0;

out:
  if (planes) {
    drmModeFreePlaneResources(planes);
  }
  if (crtc) {
    drmModeFreeCrtc(crtc);
  }
  if (encoder) {
    drmModeFreeEncoder(encoder);
  }
  if (connector) {
    drmModeFreeConnector(connector);
  }
  drmModeFreeResources(resources);
  return output->valid;
}

static int snapshot_display(int fd, struct saved_display *display) {
  drmModePlaneRes *resources;
  uint32_t index;

  memset(display, 0, sizeof(*display));
  display->master_index = -1;
  if (!snapshot_output(fd, &display->output)) {
    return 0;
  }
  (void)drmSetClientCap(fd, DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1);
  (void)drmSetClientCap(fd, DRM_CLIENT_CAP_ATOMIC, 1);
  resources = drmModeGetPlaneResources(fd);
  if (!resources) {
    return 0;
  }
  for (index = 0; index < resources->count_planes &&
                  display->plane_count < MAX_SAVED_PLANES;
       index++) {
    drmModePlane *current = drmModeGetPlane(fd, resources->planes[index]);
    struct saved_plane *saved;

    if (!current) {
      continue;
    }
    if (!current->crtc_id || !current->fb_id) {
      drmModeFreePlane(current);
      continue;
    }
    saved = &display->planes[display->plane_count];
    memset(saved, 0, sizeof(*saved));
    saved->plane_id = current->plane_id;
    saved->crtc_id = current->crtc_id;
    saved->fb_id = current->fb_id;
    if (snapshot_plane_geometry(fd, saved)) {
      display->plane_count++;
    }
    drmModeFreePlane(current);
  }
  drmModeFreePlaneResources(resources);
  display->valid = display->plane_count > 0;
  return display->valid;
}

static int restore_output(int fd, const struct saved_output *output) {
  drmModeObjectProperties *properties;
  drmModeModeInfo mode;
  uint32_t connector_id;
  uint32_t index;
  int ok;

  if (!output->valid) {
    return 0;
  }
  connector_id = output->connector_id;
  mode = output->mode;
  ok = drmModeSetCrtc(fd, output->crtc_id, output->fb_id, output->x,
                      output->y, &connector_id, 1, &mode) == 0;
  properties = drmModeObjectGetProperties(fd, output->connector_id,
                                          DRM_MODE_OBJECT_CONNECTOR);
  if (!properties) {
    return ok;
  }
  for (index = 0; index < properties->count_props; index++) {
    drmModePropertyRes *property =
        drmModeGetProperty(fd, properties->props[index]);
    if (!property) {
      continue;
    }
    if (strcmp(property->name, "DPMS") == 0) {
      if (drmModeObjectSetProperty(fd, output->connector_id,
                                   DRM_MODE_OBJECT_CONNECTOR,
                                   property->prop_id, DRM_MODE_DPMS_ON) != 0) {
        ok = 0;
      }
      drmModeFreeProperty(property);
      break;
    }
    drmModeFreeProperty(property);
  }
  drmModeFreeObjectProperties(properties);
  return ok;
}

static int restore_display(int fd, const struct saved_display *display) {
  size_t index;
  int ok;

  if (!display->valid || !restore_output(fd, &display->output)) {
    return 0;
  }
  ok = 1;
  for (index = 0; index < display->plane_count; index++) {
    const struct saved_plane *plane = &display->planes[index];
    if (drmModeSetPlane(fd, plane->plane_id, plane->crtc_id, plane->fb_id, 0,
                        plane->crtc_x, plane->crtc_y, plane->crtc_w,
                        plane->crtc_h, plane->src_x, plane->src_y,
                        plane->src_w, plane->src_h) != 0) {
      ok = 0;
    }
  }
  return ok;
}

static int operate_on_shared_fds(struct shared_drm_fd *fds, size_t count,
                                 int set_master, int *saved_errno,
                                 int *success_index) {
  size_t index;
  int success = 0;
  int error_value = ENODEV;

  for (index = 0; index < count; index++) {
    if (set_master && !fds[index].dropped) {
      continue;
    }
    if (ioctl(fds[index].fd, set_master ? DRM_IOCTL_SET_MASTER
                                        : DRM_IOCTL_DROP_MASTER,
              0) == 0) {
      success = 1;
      fds[index].dropped = set_master ? 0 : 1;
      if (success_index) {
        *success_index = (int)index;
      }
    } else {
      error_value = errno;
    }
  }
  if (saved_errno) {
    *saved_errno = success ? 0 : error_value;
  }
  return success;
}

static void serve_client(int client, struct shared_drm_fd *fds,
                         size_t fd_count, struct saved_display *display) {
  char request[32];
  char reply[96];
  ssize_t length;
  int set_master;
  int success_index = -1;
  int saved_errno = 0;

  length = read(client, request, sizeof(request) - 1);
  if (length <= 0) {
    return;
  }
  request[length] = '\0';
  if (strncmp(request, "save", 4) == 0) {
    size_t index;
    for (index = 0; index < fd_count; index++) {
      if (snapshot_display(fds[index].fd, display)) {
        int reply_length = snprintf(reply, sizeof(reply),
                                    "ok planes=%zu\n", display->plane_count);
        (void)write(client, reply, (size_t)reply_length);
        return;
      }
    }
    (void)write(client, "error snapshot\n", 15);
    return;
  } else if (strncmp(request, "restore", 7) == 0) {
    if (display->valid && display->master_index >= 0 &&
        (size_t)display->master_index < fd_count &&
        restore_display(fds[display->master_index].fd, display)) {
      display->valid = 0;
      (void)write(client, "ok\n", 3);
    } else {
      (void)write(client, "error restore\n", 14);
    }
    return;
  } else if (strncmp(request, "drop", 4) == 0) {
    set_master = 0;
  } else if (strncmp(request, "set", 3) == 0) {
    set_master = 1;
  } else {
    (void)write(client, "error command\n", 14);
    return;
  }
  if (operate_on_shared_fds(fds, fd_count, set_master, &saved_errno,
                            &success_index)) {
    display->master_index = success_index;
    (void)write(client, "ok\n", 3);
  } else {
    int reply_length = snprintf(reply, sizeof(reply), "error %d %s\n",
                                saved_errno, strerror(saved_errno));
    if (reply_length > 0) {
      (void)write(client, reply, (size_t)reply_length);
    }
  }
}

static int child_exit_code(int status) {
  if (WIFEXITED(status)) {
    return WEXITSTATUS(status);
  }
  if (WIFSIGNALED(status)) {
    return 128 + WTERMSIG(status);
  }
  return 1;
}

int main(int argc, char **argv) {
  const char *library = NULL;
  const char *runtime_root;
  char handoff_directory[256];
  char socket_path[sizeof(((struct sockaddr_un *)0)->sun_path)];
  char channel_value[32];
  int command_index = 1;
  int channels[2] = {-1, -1};
  int server = -1;
  struct shared_drm_fd shared_fds[MAX_SHARED_FDS];
  struct saved_display saved_display;
  size_t shared_count = 0;
  pid_t child;
  int status = 0;
  int child_finished = 0;
  struct sockaddr_un address;
  struct sigaction action;

  while (command_index < argc) {
    if (strcmp(argv[command_index], "--library") == 0 &&
        command_index + 1 < argc) {
      library = argv[command_index + 1];
      command_index += 2;
    } else if (strcmp(argv[command_index], "--") == 0) {
      command_index++;
      break;
    } else {
      break;
    }
  }
  if (!library || !library[0] || command_index >= argc) {
    fprintf(stderr, "usage: %s --library PATH -- COMMAND [ARG...]\n", argv[0]);
    return 2;
  }
  runtime_root = getenv("PLUMOS_RUNTIME_ROOT");
  if (!runtime_root || !runtime_root[0]) {
    runtime_root = "/run/plumos";
  }
  if (snprintf(handoff_directory, sizeof(handoff_directory),
               "%s/drm-handoff", runtime_root) >=
      (int)sizeof(handoff_directory) || !make_directory(runtime_root) ||
      !make_directory(handoff_directory)) {
    fprintf(stderr, "plumos-drm-broker: cannot create handoff directory\n");
    return 1;
  }
  if (socketpair(AF_UNIX, SOCK_DGRAM, 0, channels) != 0) {
    perror("plumos-drm-broker: socketpair");
    return 1;
  }
  if (fcntl(channels[1], F_SETFD, 0) != 0) {
    perror("plumos-drm-broker: channel inheritance");
    close(channels[0]);
    close(channels[1]);
    return 1;
  }

  child = fork();
  if (child < 0) {
    perror("plumos-drm-broker: fork");
    close(channels[0]);
    close(channels[1]);
    return 1;
  }
  if (child == 0) {
    close(channels[0]);
    (void)prctl(PR_SET_PDEATHSIG, SIGTERM);
    snprintf(channel_value, sizeof(channel_value), "%d", channels[1]);
    if (setenv("PLUMOS_DRM_BROKER_FD", channel_value, 1) != 0 ||
        setenv("PLUMOS_DRM_SHARE_LIBRARY", library, 1) != 0) {
      _exit(126);
    }
    execvp(argv[command_index], &argv[command_index]);
    _exit(127);
  }

  close(channels[1]);
  channels[1] = -1;
  (void)prctl(PR_SET_NAME, "plumos-drm-broker");
  if (snprintf(socket_path, sizeof(socket_path), "%s/%ld.sock",
               handoff_directory, (long)getpid()) >= (int)sizeof(socket_path)) {
    kill(child, SIGTERM);
    close(channels[0]);
    (void)waitpid(child, &status, 0);
    return 1;
  }
  server = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (server < 0) {
    perror("plumos-drm-broker: socket");
    kill(child, SIGTERM);
    close(channels[0]);
    (void)waitpid(child, &status, 0);
    return 1;
  }
  memset(&address, 0, sizeof(address));
  address.sun_family = AF_UNIX;
  snprintf(address.sun_path, sizeof(address.sun_path), "%s", socket_path);
  unlink(socket_path);
  if (bind(server, (struct sockaddr *)&address, sizeof(address)) != 0 ||
      chmod(socket_path, 0600) != 0 || listen(server, 4) != 0) {
    perror("plumos-drm-broker: bind/listen");
    kill(child, SIGTERM);
    close(server);
    close(channels[0]);
    unlink(socket_path);
    (void)waitpid(child, &status, 0);
    return 1;
  }

  memset(&action, 0, sizeof(action));
  action.sa_handler = catch_signal;
  sigemptyset(&action.sa_mask);
  (void)sigaction(SIGTERM, &action, NULL);
  (void)sigaction(SIGINT, &action, NULL);
  (void)sigaction(SIGHUP, &action, NULL);
  memset(&saved_display, 0, sizeof(saved_display));
  saved_display.master_index = -1;

  while (!child_finished) {
    struct pollfd poll_fds[2];
    int poll_result;
    pid_t waited;

    if (caught_signal) {
      kill(child, caught_signal);
    }
    poll_fds[0].fd = channels[0];
    poll_fds[0].events = POLLIN;
    poll_fds[0].revents = 0;
    poll_fds[1].fd = server;
    poll_fds[1].events = POLLIN;
    poll_fds[1].revents = 0;
    poll_result = poll(poll_fds, 2, 100);
    if (poll_result > 0 && (poll_fds[0].revents & POLLIN)) {
      int shared_fd = receive_shared_fd(channels[0]);
      if (shared_fd >= 0) {
        if (shared_count < MAX_SHARED_FDS) {
          shared_fds[shared_count].fd = shared_fd;
          shared_fds[shared_count].dropped = 0;
          shared_count++;
        } else {
          close(shared_fd);
        }
      }
    }
    if (poll_result > 0 && (poll_fds[1].revents & POLLIN)) {
      int client = accept4(server, NULL, NULL, SOCK_CLOEXEC);
      if (client >= 0) {
        serve_client(client, shared_fds, shared_count, &saved_display);
        close(client);
      }
    }
    waited = waitpid(child, &status, WNOHANG);
    if (waited == child) {
      child_finished = 1;
    } else if (waited < 0 && errno != EINTR) {
      status = 1 << 8;
      child_finished = 1;
    }
  }

  close(server);
  close(channels[0]);
  while (shared_count > 0) {
    close(shared_fds[--shared_count].fd);
  }
  unlink(socket_path);
  return child_exit_code(status);
}

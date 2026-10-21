#define _GNU_SOURCE

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int redirect_reported;

static const char *redirect_pwm_path(const char *path, char *redirected,
                                     size_t redirected_size) {
    const char *compat_root;
    const char *sysfs_root;
    char expected[PATH_MAX];
    int chip;

    if (!path)
        return path;
    compat_root = getenv("PLUMOS_PORTMASTER_PWM_COMPAT_ROOT");
    if (!compat_root || !*compat_root)
        return path;
    sysfs_root = getenv("PLUMOS_PORTMASTER_PWM_SYSFS_ROOT");
    if (!sysfs_root || !*sysfs_root)
        sysfs_root = "/sys/class/pwm";

    for (chip = 0; chip <= 1; chip++) {
        if (snprintf(expected, sizeof(expected), "%s/pwmchip%d/pwm0/duty_cycle",
                     sysfs_root, chip) >= (int)sizeof(expected))
            continue;
        if (strcmp(path, expected) != 0 || access(path, F_OK) == 0)
            continue;
        if (snprintf(redirected, redirected_size, "%s/pwmchip%d-duty_cycle",
                     compat_root, chip) >= (int)redirected_size) {
            errno = ENAMETOOLONG;
            return path;
        }
        if (!redirect_reported) {
            static const char message[] =
                "plumos-portmaster-hw-compat: unavailable raw PWM redirected "
                "to a no-op runtime file\n";
            (void)write(STDERR_FILENO, message, sizeof(message) - 1);
            redirect_reported = 1;
        }
        return redirected;
    }
    return path;
}

FILE *fopen(const char *path, const char *mode) {
    static FILE *(*real_fopen)(const char *, const char *);
    char redirected[PATH_MAX];

    if (!real_fopen)
        real_fopen = dlsym(RTLD_NEXT, "fopen");
    if (!real_fopen) {
        errno = ENOSYS;
        return NULL;
    }
    return real_fopen(redirect_pwm_path(path, redirected, sizeof(redirected)), mode);
}

FILE *fopen64(const char *path, const char *mode) {
    static FILE *(*real_fopen64)(const char *, const char *);
    char redirected[PATH_MAX];

    if (!real_fopen64)
        real_fopen64 = dlsym(RTLD_NEXT, "fopen64");
    if (!real_fopen64) {
        errno = ENOSYS;
        return NULL;
    }
    return real_fopen64(redirect_pwm_path(path, redirected, sizeof(redirected)), mode);
}

static int open_needs_mode(int flags) {
    if (flags & O_CREAT)
        return 1;
#ifdef O_TMPFILE
    if ((flags & O_TMPFILE) == O_TMPFILE)
        return 1;
#endif
    return 0;
}

int open(const char *path, int flags, ...) {
    static int (*real_open)(const char *, int, ...);
    char redirected[PATH_MAX];
    mode_t mode = 0;
    va_list arguments;

    if (open_needs_mode(flags)) {
        va_start(arguments, flags);
        mode = va_arg(arguments, mode_t);
        va_end(arguments);
    }
    if (!real_open)
        real_open = dlsym(RTLD_NEXT, "open");
    if (!real_open) {
        errno = ENOSYS;
        return -1;
    }
    path = redirect_pwm_path(path, redirected, sizeof(redirected));
    return open_needs_mode(flags) ? real_open(path, flags, mode) : real_open(path, flags);
}

int open64(const char *path, int flags, ...) {
    static int (*real_open64)(const char *, int, ...);
    char redirected[PATH_MAX];
    mode_t mode = 0;
    va_list arguments;

    if (open_needs_mode(flags)) {
        va_start(arguments, flags);
        mode = va_arg(arguments, mode_t);
        va_end(arguments);
    }
    if (!real_open64)
        real_open64 = dlsym(RTLD_NEXT, "open64");
    if (!real_open64) {
        errno = ENOSYS;
        return -1;
    }
    path = redirect_pwm_path(path, redirected, sizeof(redirected));
    return open_needs_mode(flags) ? real_open64(path, flags, mode) : real_open64(path, flags);
}

int openat(int directory, const char *path, int flags, ...) {
    static int (*real_openat)(int, const char *, int, ...);
    char redirected[PATH_MAX];
    mode_t mode = 0;
    va_list arguments;

    if (open_needs_mode(flags)) {
        va_start(arguments, flags);
        mode = va_arg(arguments, mode_t);
        va_end(arguments);
    }
    if (!real_openat)
        real_openat = dlsym(RTLD_NEXT, "openat");
    if (!real_openat) {
        errno = ENOSYS;
        return -1;
    }
    path = redirect_pwm_path(path, redirected, sizeof(redirected));
    return open_needs_mode(flags) ? real_openat(directory, path, flags, mode)
                                  : real_openat(directory, path, flags);
}

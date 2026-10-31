#!/usr/bin/env python3
"""Keep every current launch route in the historical device-validation ledger."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "package/frontend-mini-plus/plumos/config/frontend/systems.json"
OUTPUT = ROOT / "configs/mini-plus-runtime-validation.json"
REPORTS = [ROOT / ("artifacts/device-validation/2026-10-21-mini-plus-rom2-" + name + ".json")
           for name in ("full-matrix", "targeted-rerun", "coleco-cps3-rerun")]

def catalog_keys():
    return {(s["id"], p) for s in json.loads(CATALOG.read_text())["systems"]
            for p in s["launch_profiles"]}

def verify(doc):
    rows=doc["routes"]
    keys=[(r["system"],r["profile"]) for r in rows]
    assert len(keys)==len(set(keys)) and set(keys)==catalog_keys(), "catalog/validation route mismatch"
    assert doc["catalog_sha256"]==hashlib.sha256(CATALOG.read_bytes()).hexdigest()
    for r in rows:
        assert r["state"] in {"machine_started", "not_validated"}
        if r["state"]=="not_validated": assert r["reason"]
    print("miniplus_runtime_validation=result-ok routes=%d machine_started=%d not_validated=%d" %
          (len(rows),sum(r["state"]=="machine_started" for r in rows),
           sum(r["state"]=="not_validated" for r in rows)))

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify",action="store_true")
    args=parser.parse_args()
    if args.verify:
        verify(json.loads(OUTPUT.read_text())); return
    merged={}; evidence=[]
    for path in REPORTS:
        evidence.append({"path":str(path.relative_to(ROOT)),"sha256":hashlib.sha256(path.read_bytes()).hexdigest()})
        for r in json.loads(path.read_text())["records"]:
            merged[r["system"],r["profile"]]=r
    rows=[]
    for system,profile in sorted(catalog_keys()):
        r=merged[system,profile]
        reason=r.get("reason") or ""
        if r["status"]=="failed" and system in {"cps1","cps2"}:
            reason="provided_rom_set_missing_parent_archive"
        note=""
        if system=="ports":
            note="Apotris has separate user audio/play acceptance; this is not acceptance of every PortMaster port"
        rows.append({"system":system,"profile":profile,
                     "state":"machine_started" if r["status"]=="started" else "not_validated",
                     "reason":reason,"historical_probe_status":r["status"],"note":note})
    doc={"schema":1,"device":"mini-plus","catalog_sha256":hashlib.sha256(CATALOG.read_bytes()).hexdigest(),
         "scope":"historical machine launch evidence, not universal visual/audio/input acceptance",
         "support_policy":"validation content failures do not remove routes or mark the runtime unsupported",
         "evidence":evidence,"routes":rows}
    verify(doc)
    OUTPUT.write_text(json.dumps(doc,indent=2,ensure_ascii=False)+"\n")

if __name__=="__main__": main()

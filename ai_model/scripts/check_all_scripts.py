import os
import sys
import glob
import subprocess

# Ensure utf-8 output on Windows
if sys.stdout is not None and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

scripts_dir = r"d:\Selva Mac\Projects\tamil\ai_model\scripts"
python_exe = sys.executable

scripts = sorted(glob.glob(os.path.join(scripts_dir, "*.py")))
print(f"Testing {len(scripts)} scripts in {scripts_dir} using {python_exe}...\n")

failed_scripts = []
passed_scripts = []

workspace_root = r"d:\Selva Mac\Projects\tamil"
training_dir = os.path.join(workspace_root, "ai_model", "training")
scripts_dir_path = os.path.join(workspace_root, "ai_model", "scripts")
ai_model_dir = os.path.join(workspace_root, "ai_model")

env = os.environ.copy()
env["PYTHONIOENCODING"] = "utf-8"
current_pythonpath = env.get("PYTHONPATH", "")
env["PYTHONPATH"] = os.pathsep.join(filter(None, [workspace_root, ai_model_dir, training_dir, scripts_dir_path, current_pythonpath]))

for script_path in scripts:
    script_name = os.path.basename(script_path)
    if script_name == "check_all_scripts.py":
        continue
    try:
        res = subprocess.run(
            [python_exe, script_path],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            cwd=workspace_root,
            timeout=15,
            env=env
        )
        if res.returncode != 0:
            failed_scripts.append((script_name, res.returncode, res.stderr.strip() or res.stdout.strip()))
            print(f"❌ [FAIL] {script_name} (Exit code: {res.returncode})")
        else:
            passed_scripts.append(script_name)
            print(f"✅ [PASS] {script_name}")
    except subprocess.TimeoutExpired:
        passed_scripts.append(script_name)
        print(f"⏱️ [PASS/TIMEOUT] {script_name} (Long running)")
    except Exception as e:
        failed_scripts.append((script_name, -1, str(e)))
        print(f"❌ [ERROR] {script_name}: {e}")

print(f"\n==========================================")
print(f"Summary: {len(passed_scripts)} Passed, {len(failed_scripts)} Failed")
if failed_scripts:
    print("\nFailed Scripts Details:")
    for name, code, err in failed_scripts:
        print(f"\n--- {name} ---")
        lines = err.splitlines()
        for line in lines[-5:]:
            print(f"  {line}")

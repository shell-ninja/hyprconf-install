#!/usr/bin/env bash
# Direct execution guard
"exec" "python3" "$0" "$@"
"""
Hyprconf Modern Interactive TUI Installer
Inspired by Ryoku Shell installer design aesthetics.
Pair programmed for Shell Ninja (https://github.com/shell-ninja)
"""

import sys
import os
import time
import shutil
import signal
import termios
import tty
import select
import subprocess
import threading
import re
import atexit
import urllib.request
from datetime import datetime

# ----------------- ANSI Color Palette (Modern Obsidian / Slate & Iris)
def rgb_fg(r, g, b):
    return f"\033[38;2;{r};{g};{b}m"

def rgb_bg(r, g, b):
    return f"\033[48;2;{r};{g};{b}m"

RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
ITALIC = "\033[3m"
CLEAR_LINE = "\033[K"

# Vibrant Tokyo Night / Catppuccin Cyber Palette
COLOR_ACCENT = rgb_fg(192, 132, 252)       # Vivid Iris Lavender (#c084fc)
COLOR_ACCENT_ALT = rgb_fg(168, 85, 247)   # Rich Violet (#a855f7)
COLOR_CYAN = rgb_fg(56, 189, 248)         # Vivid Sky Cyan (#38bdf8)
COLOR_GLACIER = rgb_fg(125, 207, 255)     # Electric Glacier Cyan (#7dcfff)
COLOR_GREEN = rgb_fg(74, 222, 128)        # Crisp Emerald Green (#4ade80)
COLOR_MINT = rgb_fg(80, 250, 123)         # Neon Mint (#50fa7b)
COLOR_RED = rgb_fg(248, 113, 113)         # Coral Red (#f87171)
COLOR_YELLOW = rgb_fg(251, 191, 36)       # Amber Gold (#fbbf24)
COLOR_PURPLE = rgb_fg(189, 147, 249)      # Neon Dracula Purple (#bd93f9)
COLOR_WHITE = rgb_fg(255, 255, 255)       # Pure Crisp White (#ffffff)
COLOR_TEXT = rgb_fg(241, 245, 249)        # Slate 100 Crisp Primary (#f1f5f9)
COLOR_TEXT_BRIGHT = rgb_fg(255, 255, 255) # Pure White (#ffffff)
COLOR_TEXT_DIM = rgb_fg(203, 213, 225)    # Slate 300 Readable Secondary (#cbd5e1)
COLOR_MUTED = rgb_fg(148, 163, 184)       # Slate 400 Readable Slate (#94a3b8)
COLOR_DIM = rgb_fg(100, 116, 139)         # Slate 500 Subtle (#64748b)
COLOR_DARK_BAR = rgb_fg(71, 85, 105)      # Slate 600 Visible Track (#475569)

BORDER_COLOR = rgb_fg(129, 140, 248)      # Crisp Lavender / Indigo Frame (#818cf8)
BORDER_ACTIVE = rgb_fg(192, 132, 252)     # Vivid Iris Violet (#c084fc)
BORDER_CONSOLE = rgb_fg(99, 102, 241)     # Indigo Console Border (#6366f1)

# ----------------- Terminal Screen Management
def enter_alt_screen():
    # Alternate screen buffer + clear + hide cursor + enable SGR mouse tracking (1000, 1006) + alt-scroll (1007)
    sys.stdout.write("\033[?1049h\033[2J\033[H\033[?25l\033[?1000h\033[?1006h\033[?1007h")
    sys.stdout.flush()

def exit_alt_screen():
    # Disable mouse tracking + restore normal screen + show cursor
    sys.stdout.write("\033[?1000l\033[?1006l\033[?1007l\033[?1049l\033[?25h")
    sys.stdout.flush()

def hide_cursor():
    sys.stdout.write("\033[?25l")
    sys.stdout.flush()

def show_cursor():
    sys.stdout.write("\033[?25h")
    sys.stdout.flush()

def clear_screen():
    sys.stdout.write("\033[2J\033[H")
    sys.stdout.flush()

def strip_ansi(text):
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)

def visible_len(text):
    return len(strip_ansi(text))

def ansi_truncate(text, max_vis_len):
    """Truncates text while preserving ANSI escape sequences and resetting at the end."""
    if max_vis_len <= 0:
        return ""
    ansi_re = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    vis_count = 0
    res = []
    i = 0
    n = len(text)
    truncated = False
    while i < n:
        m = ansi_re.match(text, i)
        if m:
            res.append(m.group(0))
            i = m.end()
            continue
        if vis_count >= max_vis_len:
            truncated = True
            break
        res.append(text[i])
        vis_count += 1
        i += 1
    if truncated:
        res.append(RESET)
    return "".join(res)

def colorize_log_line(line):
    if not line:
        return ""
    if "[SKIP]" in line:
        return line.replace("[SKIP]", f"{COLOR_YELLOW}{BOLD}[SKIP]{RESET}{COLOR_TEXT_DIM}")
    if "[DONE]" in line:
        return line.replace("[DONE]", f"{COLOR_MINT}{BOLD}[DONE]{RESET}{COLOR_TEXT_DIM}")
    if line.startswith("::"):
        return f"{COLOR_CYAN}{line}{RESET}"
    if line.startswith("→"):
        return f"{COLOR_CYAN}{BOLD}→{RESET}{COLOR_TEXT}{line[1:]}{RESET}"
    if line.startswith("$"):
        return f"{COLOR_ACCENT}{BOLD}${RESET}{COLOR_TEXT}{line[1:]}{RESET}"
    if "error:" in line.lower():
        return f"{COLOR_RED}{line}{RESET}"
    if "warning:" in line.lower():
        return f"{COLOR_YELLOW}{line}{RESET}"
    return f"{COLOR_TEXT_DIM}{line}{RESET}"

def make_box_row(content_str, box_w, box_pad="", border_color=BORDER_COLOR, pad_left=2, pad_right=2):
    """
    Renders a pixel-perfect box line with exact character alignment.
    Total visible width = len(box_pad) + box_w
    """
    avail_w = (box_w - 2) - pad_left - pad_right
    content_vis_len = visible_len(content_str)
    if content_vis_len > avail_w:
        content_str = ansi_truncate(content_str, avail_w)
        content_vis_len = visible_len(content_str)
    fill_spaces = max(0, avail_w - content_vis_len)
    return (
        f"{box_pad}{border_color}│{RESET}"
        f"{' ' * pad_left}"
        f"{content_str}"
        f"{' ' * fill_spaces}"
        f"{' ' * pad_right}"
        f"{border_color}│{RESET}"
    )

def make_box_header(title, box_w, box_pad="", border_color=BORDER_COLOR, title_color=COLOR_ACCENT):
    inner_len = box_w - 2
    vis_title = visible_len(title)
    if vis_title > inner_len - 6:
        title = title[:inner_len - 9] + "..."
        vis_title = visible_len(title)
    fill = max(0, inner_len - vis_title - 3)
    return f"{box_pad}{border_color}╭─ {title_color}{BOLD}{title}{RESET}{border_color} {'─' * fill}╮{RESET}"

def make_box_footer(box_w, box_pad="", border_color=BORDER_COLOR):
    return f"{box_pad}{border_color}╰{'─' * (box_w - 2)}╯{RESET}"

# ----------------- Hardware & System Info Detection
def detect_os():
    if os.path.exists('/etc/os-release'):
        with open('/etc/os-release') as f:
            for line in f:
                if line.startswith('PRETTY_NAME='):
                    return line.split('=', 1)[1].strip('"\n')
                elif line.startswith('NAME='):
                    return line.split('=', 1)[1].strip('"\n')
    return "Linux"

def detect_distro_id():
    if os.path.exists('/etc/os-release'):
        with open('/etc/os-release') as f:
            for line in f:
                if line.startswith('ID='):
                    return line.split('=', 1)[1].strip('"\n').lower()
    return "linux"

def detect_gpu():
    try:
        lspci = subprocess.check_output('lspci 2>/dev/null', shell=True).decode()
        for line in lspci.split('\n'):
            if any(k in line.lower() for k in ['vga compatible controller', '3d controller', 'display controller']):
                parts = line.split(': ', 1)
                gpu = parts[-1].strip() if len(parts) > 1 else line.strip()
                for prefix in [
                    'Advanced Micro Devices, Inc. [AMD/ATI]',
                    'NVIDIA Corporation',
                    'Intel Corporation'
                ]:
                    gpu = gpu.replace(prefix, '').strip()
                gpu = re.sub(r'\[([^\]]+)\]', r'\1', gpu)
                return gpu[:45]
    except Exception:
        pass
    return "Standard Display Controller"

def is_nvidia_present():
    try:
        lspci = subprocess.check_output('lspci 2>/dev/null', shell=True).decode().lower()
        return 'nvidia' in lspci
    except Exception:
        return False

def detect_cpu():
    try:
        with open('/proc/cpuinfo') as f:
            for line in f:
                if 'model name' in line:
                    model = line.split(':', 1)[1].strip()
                    model = re.sub(r'\((R|TM)\)', '', model)
                    model = re.sub(r'\s+', ' ', model)
                    return model[:28].strip()
    except Exception:
        pass
    return "CPU"

def detect_ram():
    try:
        with open('/proc/meminfo') as f:
            for line in f:
                if 'MemTotal:' in line:
                    kb = int(line.split()[1])
                    gb = round(kb / (1024 * 1024))
                    return f"{gb}GB"
    except Exception:
        pass
    return ""

def detect_kernel():
    try:
        rel = os.uname().release
        return rel.split('-')[0]
    except Exception:
        return ""

def detect_chassis():
    try:
        if os.path.exists("/sys/class/power_supply/BAT0") or any(
            "BAT" in name for name in os.listdir("/sys/class/power_supply")
            if os.path.isdir(os.path.join("/sys/class/power_supply", name))
        ):
            return "Laptop"
    except Exception:
        pass
    return "Desktop"

def detect_keyboard():
    try:
        out = subprocess.check_output(
            "localectl status 2>/dev/null | awk -F': ' '/X11 Layout|VC Keymap/ {print $2; exit}'",
            shell=True
        ).decode().strip()
        if out and out.lower() != 'n/a':
            return out
    except Exception:
        pass
    return "us"

def detect_timezone():
    try:
        out = subprocess.check_output("timedatectl show --property=Timezone --value 2>/dev/null", shell=True).decode().strip()
        if out:
            return out
    except Exception:
        pass
    try:
        if os.path.exists("/etc/timezone"):
            with open("/etc/timezone", "r") as f:
                tz = f.read().strip()
                if tz:
                    return tz
    except Exception:
        pass
    try:
        if os.path.exists("/etc/localtime"):
            target = os.path.realpath("/etc/localtime")
            if "zoneinfo/" in target:
                return target.split("zoneinfo/", 1)[1]
    except Exception:
        pass
    return ""

def detect_pkgman():
    for cmd, name in [('pacman', 'pacman'), ('dnf', 'dnf'), ('zypper', 'zypper'), ('apt-get', 'apt')]:
        if shutil.which(cmd):
            return name
    return "pacman"

# ----------------- Keyboard & Mouse Reader with cbreak (Unbuffered OS-level)
class InputManager:
    def __init__(self):
        self.fd = sys.stdin.fileno() if sys.stdin.isatty() else None
        self.old_settings = None
        self.buf = ""

    def enable(self):
        if self.fd is None:
            return
        self.old_settings = termios.tcgetattr(self.fd)
        tty.setcbreak(self.fd)
        hide_cursor()

    def disable(self):
        if self.old_settings is not None and self.fd is not None:
            termios.tcsetattr(self.fd, termios.TCSADRAIN, self.old_settings)
            self.old_settings = None
        show_cursor()

    def get_key(self, timeout=None):
        if self.fd is None:
            time.sleep(timeout or 0.1)
            return None

        # If internal buffer is empty, wait for input via select on fd
        if not self.buf:
            r, _, _ = select.select([self.fd], [], [], timeout)
            if not r:
                return None
            try:
                raw = os.read(self.fd, 1024)
                if not raw:
                    return None
                self.buf += raw.decode('utf-8', errors='ignore')
            except Exception:
                return None

        if not self.buf:
            return None

        # Handle escape sequences
        if self.buf[0] == '\x1b':
            # If only ESC is in buffer, give it a tiny moment (0.05s) to see if sequence bytes follow
            if len(self.buf) == 1:
                r, _, _ = select.select([self.fd], [], [], 0.05)
                if r:
                    try:
                        raw = os.read(self.fd, 1024)
                        self.buf += raw.decode('utf-8', errors='ignore')
                    except Exception:
                        pass

            # If still only ESC after wait, it is a genuine standalone ESC keypress
            if len(self.buf) == 1:
                self.buf = ""
                return 'ESC'

            # SS3 sequence (keypad / application cursor mode: \x1bOA, \x1bOB, etc.)
            if self.buf[1] == 'O':
                if len(self.buf) < 3:
                    r, _, _ = select.select([self.fd], [], [], 0.05)
                    if r:
                        try:
                            self.buf += os.read(self.fd, 1024).decode('utf-8', errors='ignore')
                        except Exception:
                            pass
                if len(self.buf) >= 3:
                    ch = self.buf[2]
                    self.buf = self.buf[3:]
                    if ch == 'A': return 'UP'
                    elif ch == 'B': return 'DOWN'
                    elif ch == 'C': return 'RIGHT'
                    elif ch == 'D': return 'LEFT'
                    elif ch == 'H': return 'HOME'
                    elif ch == 'F': return 'END'
                    elif ch == 'M': return 'ENTER'
                    return None
                else:
                    self.buf = ""
                    return None

            # CSI sequence (\x1b[...)
            elif self.buf[1] == '[':
                term_idx = -1
                for idx in range(2, len(self.buf)):
                    if 0x40 <= ord(self.buf[idx]) <= 0x7E:
                        term_idx = idx
                        break

                if term_idx == -1:
                    r, _, _ = select.select([self.fd], [], [], 0.05)
                    if r:
                        try:
                            self.buf += os.read(self.fd, 1024).decode('utf-8', errors='ignore')
                        except Exception:
                            pass
                    for idx in range(2, len(self.buf)):
                        if 0x40 <= ord(self.buf[idx]) <= 0x7E:
                            term_idx = idx
                            break

                if term_idx != -1:
                    seq = self.buf[2:term_idx + 1]
                    self.buf = self.buf[term_idx + 1:]

                    # Cursor keys (standard ANSI or modified e.g. \x1b[1;2A)
                    if seq.endswith('A'): return 'UP'
                    elif seq.endswith('B'): return 'DOWN'
                    elif seq.endswith('C'): return 'RIGHT'
                    elif seq.endswith('D'): return 'LEFT'
                    elif seq.endswith('H'): return 'HOME'
                    elif seq.endswith('F'): return 'END'
                    elif seq.endswith('Z'): return 'LEFT'  # Shift+Tab (backtab)

                    # Page keys
                    if seq.startswith('5') and seq.endswith('~'): return 'UP'
                    elif seq.startswith('6') and seq.endswith('~'): return 'DOWN'
                    elif seq.startswith('1~') or seq.startswith('7~'): return 'HOME'
                    elif seq.startswith('4~') or seq.startswith('8~'): return 'END'

                    # SGR Mouse mode: \x1b[<button;col;rowM or m
                    if seq.startswith('<'):
                        m = re.match(r'^<(\d+);(\d+);(\d+)([Mm])$', seq)
                        if m:
                            btn = int(m.group(1))
                            if btn == 64: return 'UP'
                            elif btn == 65: return 'DOWN'
                        return None

                    # X10 / Normal Mouse mode: \x1b[M cb cx cy
                    if seq.startswith('M') and len(seq) >= 4:
                        cb = ord(seq[1])
                        if cb in (96, 64 + 32): return 'UP'
                        elif cb in (97, 65 + 32): return 'DOWN'
                        return None

                    return None
                else:
                    self.buf = ""
                    return None

            # Discard any other unhandled escape prefix
            self.buf = ""
            return None

        # Single keypress
        ch = self.buf[0]
        self.buf = self.buf[1:]

        if ch in ('\r', '\n'):
            return 'ENTER'
        elif ch == ' ':
            return 'SPACE'
        elif ch == '\t':
            return 'DOWN'
        elif ch in ('k', 'K'):
            return 'UP'
        elif ch in ('j', 'J'):
            return 'DOWN'
        elif ch in ('h', 'H'):
            return 'LEFT'
        elif ch in ('l', 'L'):
            return 'RIGHT'
        elif ch in ('q', 'Q'):
            return 'QUIT'
        elif ch == '\x03':
            return 'CTRL_C'
        return ch

# ----------------- Plan State & Options
class PlanConfig:
    def __init__(self, workspace_dir):
        self.workspace_dir = workspace_dir
        self.pkgman = detect_pkgman()
        self.distro_name = detect_os()
        self.distro_id = detect_distro_id()
        self.kernel = detect_kernel()
        self.cpu_name = detect_cpu()
        self.gpu_name = detect_gpu()
        self.ram_total = detect_ram()
        self.chassis = detect_chassis()
        self.has_nvidia = is_nvidia_present()
        self.keyboard = detect_keyboard()
        self.timezone = detect_timezone()
        self.is_dhaka_tz = (self.timezone == "Asia/Dhaka")

        self.options = [
            {
                "id": "dotfiles_repo",
                "name": "Quickshell Desktop Suite",
                "desc": "Dynamic Island, App Dock, Lockscreen, Settings Studio & window rules",
                "type": "toggle",
                "enabled": True,
            },
            {
                "id": "sddm_theme",
                "name": "SDDM Greeter Theme",
                "desc": "Minimalist display manager login greeter",
                "type": "choice",
                "choices": ["Prohori", "SilentSDDM", "Skip"],
                "index": 0,
            },
            {
                "id": "bluetooth",
                "name": "Bluetooth & Audio Stack",
                "desc": "BlueZ daemon, system tray integration & audio profile management",
                "type": "toggle",
                "enabled": True,
            },
            {
                "id": "shell",
                "name": "Default User Shell",
                "desc": "Shell environment configured with aliases and functions",
                "type": "choice",
                "choices": ["Bash", "Fish", "Zsh", "Skip"],
                "index": 0,
            },
            {
                "id": "browser",
                "name": "Default Web Browser",
                "desc": "Wayland-accelerated desktop web browser",
                "type": "choice",
                "choices": ["Brave", "Google_Chrome", "Zen Browser", "Firefox", "Chromium", "Vivaldi", "Skip"],
                "index": 0,
            },
            {
                "id": "nvidia",
                "name": "NVIDIA GPU Drivers & Flags",
                "desc": "Kernel modules, hardware acceleration & environment variables",
                "type": "toggle",
                "enabled": self.has_nvidia,
            },
            {
                "id": "keyboard",
                "name": f"Keyboard Layout ({self.keyboard})",
                "desc": "Configures active keymap layout in Hyprland settings",
                "type": "toggle",
                "enabled": True,
            }
        ]

        if self.is_dhaka_tz:
            self.options.append({
                "id": "openbangla",
                "name": "Fcitx5 & OpenBangla Keyboard",
                "desc": "Bangla phonetic typing engine with Fcitx5 input method",
                "type": "toggle",
                "enabled": True,
            })

    def save_cache_files(self):
        cache_dir = os.path.join(self.workspace_dir, ".cache")
        os.makedirs(cache_dir, exist_ok=True)

        user_cache = os.path.join(cache_dir, "user-cache")
        shell_cache = os.path.join(cache_dir, "shell")
        browser_cache = os.path.join(cache_dir, "browser")
        pkgman_cache = os.path.join(cache_dir, "pkgman")

        opt_map = {opt["id"]: opt for opt in self.options}

        dotfiles_enabled = opt_map.get("dotfiles_repo", {}).get("enabled", True)
        dotfiles_choice = "hyprconf-qs" if dotfiles_enabled else "skip"
        dotfiles_cache = os.path.join(cache_dir, "dotfiles")
        with open(dotfiles_cache, "w") as f:
            f.write(f"{dotfiles_choice}\n")

        with open(pkgman_cache, "w") as f:
            f.write(f"pkgman={self.pkgman}\n")

        with open(user_cache, "w") as f:
            f.write(f"dotfiles_repo='{dotfiles_choice}'\n")
            f.write(f"hyprconf_version='quickshell'\n")
            f.write(f"setup_for_bluetooth='{'Y' if opt_map.get('bluetooth', {}).get('enabled') else 'N'}'\n")
            f.write("install_vs_code='N'\n")
            browser_choice = "Skip"
            if "browser" in opt_map:
                browser_choice = opt_map["browser"]["choices"][opt_map["browser"]["index"]]
            f.write(f"install_browser='{'N' if browser_choice == 'Skip' else 'Y'}'\n")
            f.write(f"have_nvidia='{'Y' if opt_map.get('nvidia', {}).get('enabled') else 'N'}'\n")
            sddm_choice = "Prohori"
            if "sddm_theme" in opt_map:
                sddm_opt = opt_map["sddm_theme"]
                if sddm_opt.get("type") == "choice":
                    sddm_choice = sddm_opt["choices"][sddm_opt["index"]]
                else:
                    sddm_choice = "Prohori" if sddm_opt.get("enabled", True) else "Skip"
            f.write(f"install_sddm_theme='{'N' if sddm_choice == 'Skip' else 'Y'}'\n")
            f.write(f"sddm_theme_name='{sddm_choice}'\n")
            f.write(f"install_openbangla='{'Y' if opt_map.get('openbangla', {}).get('enabled') else 'N'}'\n")

        with open(browser_cache, "w") as f:
            f.write(f"{browser_choice}\n")

        sddm_cache = os.path.join(cache_dir, "sddm_theme")
        with open(sddm_cache, "w") as f:
            f.write(f"{sddm_choice}\n")

        if self.pkgman == "pacman":
            aur_cache = os.path.join(cache_dir, "aur")
            aur_helper = shutil.which("yay") or shutil.which("paru")
            if aur_helper:
                with open(aur_cache, "w") as f:
                    f.write(f"{os.path.basename(aur_helper)}\n")
            elif not os.path.exists(aur_cache):
                with open(aur_cache, "w") as f:
                    f.write("yay-git\n")

        shell_choice = opt_map.get("shell", {}).get("choices", ["Bash"])[opt_map.get("shell", {}).get("index", 0)]
        with open(shell_cache, "w") as f:
            f.write(f"install_fish='{'Y' if shell_choice == 'Fish' else 'N'}'\n")
            f.write(f"install_zsh='{'Y' if shell_choice == 'Zsh' else 'N'}'\n")
            f.write(f"setup_bash='{'Y' if shell_choice == 'Bash' else 'N'}'\n")

# ----------------- Plan UI Renderer
def render_plan_screen(plan, selected_idx, term_w, term_h):
    lines = []

    box_w = min(max(term_w - 4, 64), 78)
    box_pad = " " * max(0, (term_w - box_w) // 2)

    lines.append("")

    # Header Card with System Specs
    lines.append(make_box_header("Hyprconf  ·  Quickshell Desktop Suite", box_w, box_pad, BORDER_COLOR, COLOR_ACCENT))

    spec_items = [plan.distro_name]
    if plan.kernel:
        spec_items.append(f"Linux {plan.kernel}")
    if plan.cpu_name and plan.cpu_name != "CPU":
        spec_items.append(plan.cpu_name)
    elif plan.gpu_name and plan.gpu_name != "Standard Display Controller":
        spec_items.append(plan.gpu_name)
    if plan.ram_total:
        spec_items.append(plan.ram_total)
    if plan.chassis:
        spec_items.append(plan.chassis)

    avail_spec_w = (box_w - 2) - 4
    spec_str = f" {COLOR_MUTED}·{RESET} ".join(f"{COLOR_CYAN}{BOLD}{item}{RESET}" for item in spec_items)
    while visible_len(spec_str) > avail_spec_w and len(spec_items) > 2:
        spec_items.pop(2)
        spec_str = f" {COLOR_MUTED}·{RESET} ".join(f"{COLOR_CYAN}{BOLD}{item}{RESET}" for item in spec_items)

    lines.append(make_box_row(spec_str, box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_footer(box_w, box_pad, BORDER_COLOR))
    lines.append("")

    # Configuration Profile Card
    lines.append(make_box_header("Configuration Profile", box_w, box_pad, BORDER_COLOR, COLOR_ACCENT))
    lines.append(make_box_row(f"{COLOR_TEXT_DIM}Select components to install and customize your desktop:{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))

    max_opt_len = max(len(opt["name"]) for opt in plan.options) + 2
    name_col_w = min(max(max_opt_len, 26), 32)

    for idx, opt in enumerate(plan.options):
        is_selected = (idx == selected_idx)
        prefix = f"{COLOR_CYAN}{BOLD}▸{RESET} " if is_selected else "  "

        if opt["type"] == "toggle":
            if opt["enabled"]:
                status = f"{COLOR_MINT}{BOLD}[●] Enabled{RESET}" if is_selected else f"{COLOR_GREEN}[●] Enabled{RESET}"
            else:
                status = f"{COLOR_MUTED}[○] Disabled{RESET}"
        else:
            curr = opt["choices"][opt["index"]]
            if is_selected:
                status = f"{COLOR_ACCENT}◄ {BOLD}{COLOR_WHITE}{curr}{RESET}{COLOR_ACCENT} ►{RESET}"
            elif curr == "Skip":
                status = f"{COLOR_DIM}Skip{RESET}"
            else:
                status = f"{COLOR_TEXT_DIM}{curr}{RESET}"

        if is_selected:
            title_styled = f"{BOLD}{COLOR_WHITE}{opt['name']:<{name_col_w}}{RESET}"
        else:
            title_styled = f"{COLOR_TEXT}{opt['name']:<{name_col_w}}{RESET}"

        row_content = f"{prefix}{title_styled}  {status}"
        lines.append(make_box_row(row_content, box_w, box_pad, BORDER_COLOR, 1, 2))

        if is_selected:
            desc_text = opt['desc']
            avail_desc_w = (box_w - 2) - 11
            if len(desc_text) > avail_desc_w:
                desc_text = desc_text[:avail_desc_w - 3] + "..."
            desc_content = f"   {COLOR_CYAN}└─{RESET} {COLOR_TEXT_DIM}{desc_text}{RESET}"
            lines.append(make_box_row(desc_content, box_w, box_pad, BORDER_COLOR, 1, 2))

    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_footer(box_w, box_pad, BORDER_COLOR))
    lines.append("")

    # Navigation Footer
    footer = (
        f"{COLOR_CYAN}[↑/↓]{RESET} {COLOR_TEXT}Select{RESET}   "
        f"{COLOR_CYAN}[Space/Tab]{RESET} {COLOR_TEXT}Change{RESET}   "
        f"{COLOR_MINT}{BOLD}[Enter]{RESET} {COLOR_WHITE}{BOLD}Install{RESET}   "
        f"{COLOR_RED}[Q]{RESET} {COLOR_TEXT}Quit{RESET}"
    )
    f_pad = " " * max(0, (term_w - visible_len(footer)) // 2)
    lines.append(f"{f_pad}{footer}")

    # Vertical centering
    total_lines = len(lines)
    top_pad_count = max(0, (term_h - total_lines) // 2)

    frame_lines = [""] * top_pad_count + lines
    while len(frame_lines) < term_h:
        frame_lines.append("")

    output = "\033[H" + "\r\n".join(l + CLEAR_LINE for l in frame_lines)
    sys.stdout.write(output)
    sys.stdout.flush()

# ----------------- Live Progress & Sub-Terminal Execution Screen
class ExecutionUI:
    def __init__(self, steps, log_path, term_w, term_h):
        self.steps = steps
        self.log_path = log_path
        self.term_w = term_w
        self.term_h = term_h
        self.current_step_idx = 0
        self.spinner_frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        self.spinner_idx = 0
        self.log_lines = []
        self.current_cmd = ""
        self.start_time = time.time()
        self.lock = threading.Lock()

    def update_size(self):
        w, h = shutil.get_terminal_size((80, 24))
        self.term_w = w
        self.term_h = h

    def add_log_line(self, line):
        clean = strip_ansi(line).rstrip()
        if not clean:
            return
        with self.lock:
            self.log_lines.append(clean)
            if len(self.log_lines) > 6:
                self.log_lines.pop(0)

    def set_cmd(self, cmd_str):
        with self.lock:
            self.current_cmd = cmd_str

    def set_step(self, idx):
        with self.lock:
            self.current_step_idx = idx

    def render(self):
        with self.lock:
            self.update_size()
            term_w = self.term_w
            term_h = self.term_h

            box_w = min(max(term_w - 4, 64), 78)
            box_pad = " " * max(0, (term_w - box_w) // 2)

            lines = []
            lines.append("")
            lines.append(make_box_header("Installing Hyprconf Desktop", box_w, box_pad, BORDER_ACTIVE, COLOR_ACCENT))
            lines.append(make_box_row("", box_w, box_pad, BORDER_ACTIVE, 2, 2))

            total_steps = max(len(self.steps), 1)
            completed_count = min(self.current_step_idx, total_steps)
            pct = int((completed_count / total_steps) * 100)

            step_title = self.steps[self.current_step_idx]['title'] if self.current_step_idx < total_steps else "Completing setup..."
            max_st_w = box_w - 6
            if len(step_title) > max_st_w - 18:
                step_title = step_title[:max_st_w - 21] + "..."

            if self.current_step_idx < total_steps:
                step_indicator = f"Step {self.current_step_idx + 1} of {total_steps}"
            else:
                step_indicator = f"Completed {total_steps} of {total_steps}"
            lines.append(make_box_row(f"{COLOR_CYAN}{BOLD}{step_indicator}{RESET}  {COLOR_MUTED}·{RESET}  {COLOR_WHITE}{BOLD}{step_title}{RESET}", box_w, box_pad, BORDER_ACTIVE, 2, 2))

            # Progress Bar & Timer
            elapsed = int(time.time() - self.start_time)
            time_str = f"{elapsed // 60:02d}:{elapsed % 60:02d}"

            bar_w = 34
            filled = int((pct / 100) * bar_w)
            bar_str = f"{COLOR_ACCENT}{BOLD}{'━' * filled}{RESET}"
            if filled < bar_w:
                bar_str += f"{COLOR_CYAN}╸{RESET}" + f"{COLOR_DARK_BAR}{'─' * (bar_w - filled - 1)}{RESET}"

            prog_line = f"[{bar_str}]  {COLOR_CYAN}{BOLD}{pct:>3}%{RESET}  {COLOR_TEXT_DIM}({time_str}){RESET}"
            lines.append(make_box_row(prog_line, box_w, box_pad, BORDER_ACTIVE, 2, 2))
            lines.append(make_box_row("", box_w, box_pad, BORDER_ACTIVE, 2, 2))

            # Step Checklist
            max_visible_steps = max(min(len(self.steps), term_h - 18), 5)
            start_s = 0
            if len(self.steps) > max_visible_steps:
                start_s = max(0, min(self.current_step_idx - 2, len(self.steps) - max_visible_steps))
            end_s = min(start_s + max_visible_steps, len(self.steps))

            for i in range(start_s, end_s):
                step = self.steps[i]
                max_step_title_w = box_w - 12
                st_title = step['title']
                if len(st_title) > max_step_title_w:
                    st_title = st_title[:max_step_title_w - 3] + "..."

                if i < self.current_step_idx:
                    icon = f"{COLOR_MINT}{BOLD}✓{RESET}"
                    label = f"{COLOR_TEXT_DIM}{st_title}{RESET}"
                elif i == self.current_step_idx:
                    spin = self.spinner_frames[self.spinner_idx % len(self.spinner_frames)]
                    icon = f"{COLOR_CYAN}{BOLD}{spin}{RESET}"
                    label = f"{BOLD}{COLOR_WHITE}{st_title}{RESET}"
                else:
                    icon = f"{COLOR_MUTED}·{RESET}"
                    label = f"{COLOR_MUTED}{st_title}{RESET}"

                lines.append(make_box_row(f" {icon}  {label}", box_w, box_pad, BORDER_ACTIVE, 2, 2))

            lines.append(make_box_row("", box_w, box_pad, BORDER_ACTIVE, 2, 2))

            # Console Window
            sub_w = box_w - 6
            sub_header = f"{BORDER_CONSOLE}┌─{RESET} {COLOR_CYAN}{BOLD}Console Output{RESET} {BORDER_CONSOLE}{'─' * (sub_w - 19)}┐{RESET}"
            lines.append(make_box_row(sub_header, box_w, box_pad, BORDER_ACTIVE, 2, 2))

            sub_lines = self.log_lines[-4:] if self.log_lines else []
            while len(sub_lines) < 4:
                sub_lines.append("")

            for l in sub_lines:
                max_log_w = sub_w - 4
                disp_l = l if len(l) <= max_log_w else l[:max_log_w - 3] + "..."
                fill = max(0, max_log_w - len(disp_l))
                colored_l = colorize_log_line(disp_l) + (" " * fill)
                lines.append(make_box_row(f"{BORDER_CONSOLE}│{RESET} {colored_l} {BORDER_CONSOLE}│{RESET}", box_w, box_pad, BORDER_ACTIVE, 2, 2))

            sub_footer = f"{BORDER_CONSOLE}└{'─' * (sub_w - 2)}┘{RESET}"
            lines.append(make_box_row(sub_footer, box_w, box_pad, BORDER_ACTIVE, 2, 2))
            lines.append(make_box_row("", box_w, box_pad, BORDER_ACTIVE, 2, 2))
            lines.append(make_box_footer(box_w, box_pad, BORDER_ACTIVE))
            lines.append("")

            # Log path
            max_log_w = term_w - 24
            disp_log = self.log_path if len(self.log_path) <= max_log_w else "..." + self.log_path[-(max_log_w - 3):]
            footer_text = f"{COLOR_MUTED}Active log:{RESET} {COLOR_CYAN}{disp_log}{RESET}"
            foot_pad = " " * max(0, (term_w - visible_len(footer_text)) // 2)
            lines.append(f"{foot_pad}{footer_text}")

            total_h = len(lines)
            top_pad = max(0, (term_h - total_h) // 2)

            frame_lines = [""] * top_pad + lines
            while len(frame_lines) < term_h:
                frame_lines.append("")

            output = "\033[H" + "\r\n".join(l + CLEAR_LINE for l in frame_lines)
            sys.stdout.write(output)
            sys.stdout.flush()

# ----------------- Finish & System Reboot Screen
def render_finish_screen(plan, term_w, term_h):
    box_w = min(max(term_w - 4, 64), 78)
    box_pad = " " * max(0, (term_w - box_w) // 2)

    lines = []
    lines.append("")
    lines.append(make_box_header("Installation Complete", box_w, box_pad, BORDER_ACTIVE, COLOR_MINT))
    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))

    lines.append(make_box_row(f"{COLOR_MINT}{BOLD}✓  Hyprland & Quickshell have been successfully installed!{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))

    lines.append(make_box_row(f"{COLOR_CYAN}{BOLD}Configured Environment:{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(f"  {COLOR_CYAN}·{RESET} {COLOR_WHITE}{BOLD}Compositor:{RESET}      {COLOR_TEXT}Hyprland (Wayland){RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(f"  {COLOR_CYAN}·{RESET} {COLOR_WHITE}{BOLD}Desktop Shell:{RESET}   {COLOR_TEXT}Quickshell (Dynamic Island, Dock, Lock){RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(f"  {COLOR_CYAN}·{RESET} {COLOR_WHITE}{BOLD}Display Manager:{RESET} {COLOR_TEXT}SDDM (Theme configured){RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(f"  {COLOR_CYAN}·{RESET} {COLOR_WHITE}{BOLD}Configuration:{RESET}   {COLOR_TEXT}~/.hyprconf/ (User state in ~/.local/share/){RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))

    lines.append(make_box_row(f"{COLOR_CYAN}{BOLD}Essential Shortcuts:{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(f"  {COLOR_ACCENT}{BOLD}Super + Return{RESET}    {COLOR_TEXT}Terminal (Kitty){RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(f"  {COLOR_ACCENT}{BOLD}Super + Space{RESET}     {COLOR_TEXT}Spotlight Omnibar / App Launcher{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(f"  {COLOR_ACCENT}{BOLD}Super + W{RESET}         {COLOR_TEXT}Wallpaper Studio{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(f"  {COLOR_ACCENT}{BOLD}Super + V{RESET}         {COLOR_TEXT}Quick Paste Clipboard Tooltip{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(f"  {COLOR_ACCENT}{BOLD}Super + X{RESET}         {COLOR_TEXT}Power & Session Menu{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))

    lines.append(make_box_row(f"{COLOR_TEXT_DIM}A system reboot is recommended to start your new session.{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_footer(box_w, box_pad, BORDER_COLOR))
    lines.append("")

    footer = (
        f"{COLOR_MINT}{BOLD}[Enter]{RESET} {COLOR_WHITE}{BOLD}Reboot System Now{RESET}   "
        f"{COLOR_MUTED}·{RESET}   "
        f"{COLOR_MUTED}[Q / Esc] Exit to Shell{RESET}"
    )
    f_pad = " " * max(0, (term_w - visible_len(footer)) // 2)
    lines.append(f"{f_pad}{footer}")

    total_h = len(lines)
    top_pad = max(0, (term_h - total_h) // 2)

    frame_lines = [""] * top_pad + lines
    while len(frame_lines) < term_h:
        frame_lines.append("")

    output = "\033[H" + "\r\n".join(l + CLEAR_LINE for l in frame_lines)
    sys.stdout.write(output)
    sys.stdout.flush()

# ----------------- Sudo Keep-Alive Thread
def sudo_keepalive(stop_event):
    while not stop_event.is_set():
        subprocess.run(["sudo", "-v"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(45)

# ----------------- Dynamic Release Resolver & Payload Prefetcher
def resolve_latest_hyprconf_tag():
    """
    Dynamically discovers the latest release tag from GitHub without hitting API rate limits.
    Falls back to 'main' if releases are unreachable.
    """
    # 1. Resolve via redirect on https://github.com/shell-ninja/hyprconf/releases/latest
    try:
        req = urllib.request.Request(
            "https://github.com/shell-ninja/hyprconf/releases/latest",
            headers={"User-Agent": "Mozilla/5.0"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            final_url = resp.geturl()
            if "/tag/" in final_url:
                tag = final_url.split("/tag/")[-1].strip("/")
                if tag:
                    return tag
    except Exception:
        pass

    # 2. Fast curl redirect check fallback
    try:
        res = subprocess.run(
            ["curl", "-sIL", "-o", "/dev/null", "-w", "%{url_effective}", "https://github.com/shell-ninja/hyprconf/releases/latest"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=5
        )
        if res.returncode == 0 and "/tag/" in res.stdout:
            tag = res.stdout.strip().split("/tag/")[-1].strip("/")
            if tag:
                return tag
    except Exception:
        pass

    return "main"

def prefetch_hyprconf_payload(workspace_dir, log_file=None):
    """
    Downloads and extracts the latest Hyprconf release in the background
    while system packages are being installed, eliminating user wait time.
    """
    cache_dir = os.path.join(workspace_dir, ".cache")
    os.makedirs(cache_dir, exist_ok=True)
    target_dir = os.path.join(cache_dir, "hyprconf")
    zip_path = os.path.join(cache_dir, "hyprconf.zip")

    if os.path.exists(os.path.join(target_dir, "setup.sh")):
        return True

    tag = resolve_latest_hyprconf_tag()
    if tag and tag != "main":
        url = f"https://github.com/shell-ninja/hyprconf/archive/refs/tags/{tag}.zip"
    else:
        url = "https://github.com/shell-ninja/hyprconf/archive/refs/heads/main.zip"

    try:
        res = subprocess.run(
            ["curl", "-sL", url, "-o", zip_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=120
        )
        if res.returncode == 0 and os.path.exists(zip_path) and os.path.getsize(zip_path) > 1000:
            shutil.rmtree(target_dir, ignore_errors=True)
            os.makedirs(target_dir, exist_ok=True)
            subprocess.run(
                ["unzip", "-q", "-o", zip_path, "-d", target_dir],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            # Flatten subfolder if packed as hyprconf-<tag>, hyprconf-main, etc.
            subdirs = [d for d in os.listdir(target_dir) if os.path.isdir(os.path.join(target_dir, d))]
            if len(subdirs) == 1 and subdirs[0].startswith("hyprconf"):
                sub_p = os.path.join(target_dir, subdirs[0])
                for item in os.listdir(sub_p):
                    shutil.move(os.path.join(sub_p, item), os.path.join(target_dir, item))
                try:
                    os.rmdir(sub_p)
                except Exception:
                    pass
            if os.path.exists(zip_path):
                os.remove(zip_path)
    except Exception:
        pass

    # Fallback to git clone if curl/unzip did not yield setup.sh
    if not os.path.exists(os.path.join(target_dir, "setup.sh")):
        try:
            shutil.rmtree(target_dir, ignore_errors=True)
            clone_target = tag if tag else "main"
            clone_res = subprocess.run(
                ["git", "clone", "--depth=1", "-b", clone_target, "https://github.com/shell-ninja/hyprconf.git", target_dir],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=180
            )
            if clone_res.returncode != 0 and clone_target != "main":
                subprocess.run(
                    ["git", "clone", "--depth=1", "-b", "main", "https://github.com/shell-ninja/hyprconf.git", target_dir],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=180
                )
        except Exception:
            pass

    if os.path.exists(os.path.join(target_dir, "setup.sh")):
        os.chmod(os.path.join(target_dir, "setup.sh"), 0o755)
        if log_file:
            try:
                with open(log_file, "a") as lf:
                    lf.write(f"[PREFETCH] Hyprconf payload ({tag}) pre-cached successfully in background\n")
            except Exception:
                pass
        return True
    return False

# ----------------- Main Orchestration Flow
def run_interactive_installer():
    workspace_dir = os.path.dirname(os.path.realpath(__file__))
    log_dir = os.path.join(workspace_dir, "Logs")
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"1-install-{datetime.now().strftime('%d-%m-%y')}.log")

    plan = PlanConfig(workspace_dir)
    inp = InputManager()

    def cleanup():
        inp.disable()
        exit_alt_screen()
    atexit.register(cleanup)

    # 1. Ask for Sudo Credentials once upfront
    clear_screen()
    print(f"\n  {COLOR_ACCENT}{BOLD}Hyprconf Installer{RESET}  ·  {COLOR_MUTED}Authenticating administrative access...{RESET}\n")
    sudo_res = subprocess.run(["sudo", "-v"])
    if sudo_res.returncode != 0:
        print(f"\n  {COLOR_RED}[!] Sudo authentication failed. Exiting.{RESET}\n")
        sys.exit(1)

    stop_sudo = threading.Event()
    sudo_thread = threading.Thread(target=sudo_keepalive, args=(stop_sudo,), daemon=True)
    sudo_thread.start()

    # Prefetch hyprconf dotfiles payload in the background while packages install
    prefetch_thread = threading.Thread(
        target=prefetch_hyprconf_payload,
        args=(workspace_dir, log_file),
        daemon=True
    )
    prefetch_thread.start()

    # Enter alternate screen buffer & enable raw input
    enter_alt_screen()
    inp.enable()

    # 2. Interactive Plan Screen
    selected_idx = 0
    while True:
        term_w, term_h = shutil.get_terminal_size((80, 24))
        render_plan_screen(plan, selected_idx, term_w, term_h)

        key = inp.get_key(timeout=0.1)
        if key == 'UP':
            selected_idx = (selected_idx - 1) % len(plan.options)
        elif key == 'DOWN':
            selected_idx = (selected_idx + 1) % len(plan.options)
        elif key in ('SPACE', 'RIGHT', 'LEFT'):
            opt = plan.options[selected_idx]
            if opt["type"] == "toggle":
                opt["enabled"] = not opt["enabled"]
            elif opt["type"] == "choice":
                delta = 1 if key in ('SPACE', 'RIGHT') else -1
                opt["index"] = (opt["index"] + delta) % len(opt["choices"])
        elif key == 'ENTER':
            break
        elif key in ('QUIT', 'CTRL_C', 'ESC'):
            inp.disable()
            exit_alt_screen()
            stop_sudo.set()
            print(f"\n  {COLOR_YELLOW}[!] Installation cancelled by user.{RESET}\n")
            sys.exit(0)

    # Save Plan choices to cache
    plan.save_cache_files()

    # 3. Assemble Dynamic Execution Steps
    pkgman = plan.pkgman
    scripts_dir = os.path.join(workspace_dir, f"{pkgman}-scripts")
    common_dir = os.path.join(workspace_dir, "common")

    opt_map = {opt["id"]: opt for opt in plan.options}

    steps = []
    # Step 0: AUR helper (Arch Linux if needed)
    if pkgman == "pacman" and os.path.exists(os.path.join(scripts_dir, "00-repo.sh")):
        aur_helper = shutil.which("yay") or shutil.which("paru")
        if not aur_helper:
            aur_cache = os.path.join(plan.workspace_dir, ".cache", "aur")
            if not os.path.exists(aur_cache):
                with open(aur_cache, "w") as f:
                    f.write("yay-git\n")
            steps.append({
                "title": "Installing AUR helper (yay)",
                "script": os.path.join(scripts_dir, "00-repo.sh"),
                "cmd": f"bash {scripts_dir}/00-repo.sh"
            })

    # Step 1: Core Hyprland
    steps.append({
        "title": "Installing core Hyprland compositor & tools",
        "script": os.path.join(scripts_dir, "2-hyprland.sh"),
        "cmd": f"bash {scripts_dir}/2-hyprland.sh"
    })

    # openSUSE hyprsunset
    if pkgman == "zypper" and os.path.exists(os.path.join(scripts_dir, "2.1-hyprsunset.sh")):
        steps.append({
            "title": "Installing hyprsunset blue-light filter",
            "script": os.path.join(scripts_dir, "2.1-hyprsunset.sh"),
            "cmd": f"bash {scripts_dir}/2.1-hyprsunset.sh"
        })

    # Debian/Ubuntu helpers
    if pkgman == "apt":
        if os.path.exists(os.path.join(scripts_dir, "2.1-hyprcursor.sh")):
            steps.append({
                "title": "Installing hyprcursor support",
                "script": os.path.join(scripts_dir, "2.1-hyprcursor.sh"),
                "cmd": f"bash {scripts_dir}/2.1-hyprcursor.sh"
            })
        if os.path.exists(os.path.join(scripts_dir, "2.2-hyprsunset.sh")):
            steps.append({
                "title": "Installing hyprsunset support",
                "script": os.path.join(scripts_dir, "2.2-hyprsunset.sh"),
                "cmd": f"bash {scripts_dir}/2.2-hyprsunset.sh"
            })

    # Step 2: Other Packages
    steps.append({
        "title": "Installing system utilities, audio & terminal tools",
        "script": os.path.join(scripts_dir, "3-other_packages.sh"),
        "cmd": f"bash {scripts_dir}/3-other_packages.sh"
    })

    # Step 3: Fonts
    steps.append({
        "title": "Installing desktop fonts & icon themes",
        "script": os.path.join(scripts_dir, "6-fonts.sh"),
        "cmd": f"bash {scripts_dir}/6-fonts.sh"
    })

    # Step 4: Web Browser (if enabled)
    browser_choice = opt_map.get("browser", {}).get("choices", ["Brave"])[opt_map.get("browser", {}).get("index", 0)]
    if browser_choice != "Skip":
        steps.append({
            "title": f"Installing web browser ({browser_choice})",
            "script": os.path.join(scripts_dir, "7-browser.sh"),
            "cmd": f"bash {scripts_dir}/7-browser.sh"
        })

    # Step 5: SDDM
    steps.append({
        "title": "Configuring SDDM display manager & service",
        "script": os.path.join(scripts_dir, "9-sddm.sh"),
        "cmd": f"bash {scripts_dir}/9-sddm.sh"
    })

    # Step 5b: SDDM theme (Prohori / SilentSDDM) — runs as a dedicated step when enabled
    sddm_choice = "Prohori"
    if "sddm_theme" in opt_map:
        sddm_opt = opt_map["sddm_theme"]
        if sddm_opt.get("type") == "choice":
            sddm_choice = sddm_opt["choices"][sddm_opt["index"]]
        else:
            sddm_choice = "Prohori" if sddm_opt.get("enabled", True) else "Skip"

    if sddm_choice != "Skip":
        steps.append({
            "title": f"Installing {sddm_choice} SDDM greeter theme & fonts",
            "script": os.path.join(common_dir, "sddm_theme.sh"),
            "cmd": f"bash {common_dir}/sddm_theme.sh {sddm_choice.lower()}"
        })

    # Step 6: XDG Desktop Portal
    steps.append({
        "title": "Configuring XDG desktop portal & screen sharing",
        "script": os.path.join(scripts_dir, "10-xdg_dp.sh"),
        "cmd": f"bash {scripts_dir}/10-xdg_dp.sh"
    })

    # Step 7: Fcitx5 & OpenBangla Keyboard (if enabled)
    if opt_map.get("openbangla", {}).get("enabled"):
        openbangla_script = os.path.join(scripts_dir, "openbangla.sh")
        if os.path.exists(openbangla_script):
            steps.append({
                "title": "Installing Fcitx5 & OpenBangla Keyboard",
                "script": openbangla_script,
                "cmd": f"bash {openbangla_script}"
            })

    # Step 8: NVIDIA (if enabled)
    if opt_map.get("nvidia", {}).get("enabled"):
        steps.append({
            "title": "Configuring NVIDIA drivers & Wayland patches",
            "script": os.path.join(scripts_dir, "nvidia.sh"),
            "cmd": f"bash {scripts_dir}/nvidia.sh"
        })

    # Step 9: Bluetooth (if enabled)
    if opt_map.get("bluetooth", {}).get("enabled"):
        steps.append({
            "title": "Setting up Bluetooth services & tray applet",
            "script": os.path.join(common_dir, "bluetooth.sh"),
            "cmd": f"bash {common_dir}/bluetooth.sh"
        })

    # Step 10: Shell selection
    shell_choice = opt_map.get("shell", {}).get("choices", ["Bash"])[opt_map.get("shell", {}).get("index", 0)]
    if shell_choice.lower() in ("fish", "zsh", "bash"):
        steps.append({
            "title": f"Configuring {shell_choice} shell & prompt",
            "script": os.path.join(common_dir, f"{shell_choice.lower()}.sh"),
            "cmd": f"bash {common_dir}/{shell_choice.lower()}.sh"
        })

    # Step 11: Uninstall conflicting
    steps.append({
        "title": "Removing conflicting packages & daemons",
        "script": os.path.join(scripts_dir, "11-uninstall.sh"),
        "cmd": f"bash {scripts_dir}/11-uninstall.sh"
    })

    # Step 12: Themes
    steps.append({
        "title": "Deploying adw-gtk3 & Kora icon packs (GTK & Qt)",
        "script": os.path.join(common_dir, "themes.sh"),
        "cmd": f"bash {common_dir}/themes.sh"
    })

    # Step 13: Hardware Profile (Laptop vs Desktop)
    is_laptop = (
        os.path.exists("/sys/class/power_supply/BAT0") or
        any("BAT" in name for name in os.listdir("/sys/class/power_supply") if os.path.isdir(os.path.join("/sys/class/power_supply", name))) if os.path.exists("/sys/class/power_supply") else False
    )
    hw_script = "laptop.sh" if is_laptop else "desktop.sh"
    steps.append({
        "title": f"Applying {'laptop battery' if is_laptop else 'desktop performance'} profiles",
        "script": os.path.join(common_dir, hw_script),
        "cmd": f"bash {common_dir}/{hw_script}"
    })

    # Step 14: Final System Verification
    steps.append({
        "title": "Running final system verification & health check",
        "script": os.path.join(scripts_dir, "12-final.sh"),
        "cmd": f"bash {scripts_dir}/12-final.sh"
    })

    # Step 15: Hyprconf Dotfiles (Interactive handoff at the very end — pre-cached in background)
    if opt_map.get("dotfiles_repo", {}).get("enabled", True):
        steps.append({
            "title": "Configuring Hyprconf (Quickshell) dotfiles & desktop suite",
            "script": os.path.join(common_dir, "hyprconf.sh"),
            "cmd": f"bash {common_dir}/hyprconf.sh",
            "interactive": True,       # TUI will pause and hand terminal to setup script
            "repo_choice": "hyprconf",
        })

    # 4. Live Progress Execution Loop
    # (Background payload prefetch was already kicked off at launch and is running in parallel)

    term_w, term_h = shutil.get_terminal_size((80, 24))
    exec_ui = ExecutionUI(steps, log_file, term_w, term_h)

    stop_spinner = threading.Event()
    def spinner_loop():
        while not stop_spinner.is_set():
            exec_ui.spinner_idx = (exec_ui.spinner_idx + 1) % len(exec_ui.spinner_frames)
            exec_ui.render()
            time.sleep(0.08)

    spin_thread = threading.Thread(target=spinner_loop, daemon=True)
    spin_thread.start()

    with open(log_file, "a") as lf:
        lf.write(f"\n--- Installation Started at {datetime.now().isoformat()} ---\n")

    for idx, step in enumerate(steps):
        exec_ui.set_step(idx)
        exec_ui.set_cmd(step["cmd"])
        exec_ui.add_log_line(f"Starting {step['title']}...")

        script_path = step["script"]
        if not os.path.exists(script_path):
            with open(log_file, "a") as lf:
                lf.write(f"[SKIP] Script not found: {script_path}\n")
            continue

        os.chmod(script_path, 0o755)

        # ── Interactive Handoff Step ────────────────────────────────────────────
        if step.get("interactive"):
            # Ensure background download completes before terminal handoff
            prefetch_thread.join(timeout=30)

            # 1. Freeze spinner, stop the TUI
            stop_spinner.set()
            spin_thread.join(timeout=0.5)
            inp.disable()
            exit_alt_screen()

            # 2. Print clean interstitial screen before native setup.sh
            os.system("clear")
            print()
            print(f"  {BORDER_COLOR}╭─ {COLOR_ACCENT}{BOLD}Hyprconf Desktop Setup{RESET} {BORDER_COLOR}{'─' * 42}╮{RESET}")
            print(f"  {BORDER_COLOR}│{RESET}  {COLOR_TEXT}All base system packages, drivers, and themes are installed.{RESET}")
            print(f"  {BORDER_COLOR}│{RESET}  {COLOR_TEXT}Launching the interactive setup wizard for user dotfiles & configs...{RESET}")
            print(f"  {BORDER_COLOR}╰{'─' * 66}╯{RESET}")
            print()
            input(f"  {COLOR_CYAN}Press Enter to launch setup...{RESET} ")
            print()

            # 3. Run the script with FULL terminal (stdin, stdout, stderr all native)
            env_interactive = os.environ.copy()
            # Remove TUI suppression flags so setup.sh gets real gum menus
            env_interactive.pop("HYPRCONF_TUI", None)
            env_interactive.pop("DEBIAN_FRONTEND", None)
            # Signal common/hyprconf.sh or hyprconf-v2.sh to skip the gum shim & pipe — full TTY handoff
            env_interactive["HYPRCONF_INTERACTIVE"] = "1"

            ret = subprocess.run([script_path], env=env_interactive)

            # 4. Log the outcome
            with open(log_file, "a") as lf:
                outcome = "OK" if ret.returncode == 0 else f"EXIT_CODE={ret.returncode}"
                lf.write(f"[INTERACTIVE] {step['title']} completed — {outcome}\n")

            # 5. Resume-prompt before returning to the TUI
            repo_disp = "Hyprconf (Quickshell)"
            print()
            print(f"  {COLOR_ACCENT}{BOLD}{'─' * 64}{RESET}")
            if ret.returncode == 0:
                print(f"  {COLOR_GREEN}✓  {repo_disp} setup completed successfully!{RESET}")
            else:
                print(f"  {COLOR_YELLOW}⚠  Setup finished with exit code {ret.returncode}.{RESET}")
                print(f"  {COLOR_MUTED}   The installer will continue with remaining steps.{RESET}")
            print(f"  {COLOR_ACCENT}{BOLD}{'─' * 64}{RESET}")
            print()
            input(f"  {COLOR_CYAN}Press Enter to return to the TUI installer...{RESET} ")

            # 6. Re-enter TUI, restart spinner
            enter_alt_screen()
            inp.enable()
            stop_spinner = threading.Event()
            def spinner_loop():  # noqa: F811
                while not stop_spinner.is_set():
                    exec_ui.spinner_idx = (exec_ui.spinner_idx + 1) % len(exec_ui.spinner_frames)
                    exec_ui.render()
                    time.sleep(0.08)
            spin_thread = threading.Thread(target=spinner_loop, daemon=True)
            spin_thread.start()
            exec_ui.add_log_line(f"{repo_disp} dotfiles configured — continuing installation...")
            continue
        # ── End Interactive Handoff ─────────────────────────────────────────────

        env = os.environ.copy()
        env["DEBIAN_FRONTEND"] = "noninteractive"
        env["HYPRCONF_TUI"] = "1"

        proc = subprocess.Popen(
            [script_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL,
            env=env,
            text=True,
            bufsize=1,
            universal_newlines=True
        )

        with open(log_file, "a") as lf:
            while True:
                line = proc.stdout.readline()
                if not line and proc.poll() is not None:
                    break
                if line:
                    clean_l = strip_ansi(line).rstrip()
                    lf.write(clean_l + "\n")
                    lf.flush()
                    exec_ui.add_log_line(clean_l)

        proc.wait()

    stop_spinner.set()
    exec_ui.set_step(len(steps))
    exec_ui.render()
    time.sleep(1)

    # 5. Apply Keyboard Layout to Hyprland Config
    if opt_map.get("keyboard", {}).get("enabled"):
        kbd_layout = plan.keyboard
        cfg_paths = [
            os.path.expanduser("~/.config/hypr/confs/settings.conf"),
            os.path.expanduser("~/.config/hypr/configs/settings.conf")
        ]
        for cfg in cfg_paths:
            if os.path.exists(cfg):
                try:
                    with open(cfg, "r") as f:
                        content = f.read()
                    content = re.sub(r"kb_layout\s*=.*", f"kb_layout = {kbd_layout}", content)
                    with open(cfg, "w") as f:
                        f.write(content)
                except Exception:
                    pass

    # 6. Ensure selected shell is applied to user account
    shell_choice = opt_map.get("shell", {}).get("choices", ["Bash"])[opt_map.get("shell", {}).get("index", 0)]
    if shell_choice.lower() in ("fish", "zsh", "bash"):
        sh_bin = shutil.which(shell_choice.lower())
        if sh_bin:
            target_user = os.environ.get("SUDO_USER") or os.environ.get("USER") or os.environ.get("LOGNAME")
            if target_user:
                try:
                    if os.path.exists("/etc/shells"):
                        with open("/etc/shells", "r") as sf:
                            shells = sf.read().splitlines()
                        if sh_bin not in shells:
                            subprocess.run(["sudo", "tee", "-a", "/etc/shells"], input=f"{sh_bin}\n", text=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    res = subprocess.run(["sudo", "usermod", "-s", sh_bin, target_user], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    if res.returncode != 0:
                        subprocess.run(["sudo", "chsh", "-s", sh_bin, target_user], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                except Exception:
                    pass

    # 7. Celebratory Finish Screen
    stop_sudo.set()
    while True:
        term_w, term_h = shutil.get_terminal_size((80, 24))
        render_finish_screen(plan, term_w, term_h)
        key = inp.get_key(timeout=0.1)
        if key == 'ENTER':
            inp.disable()
            exit_alt_screen()
            for sec in range(5, 0, -1):
                clear_screen()
                msg = f"{COLOR_ACCENT}✦ Rebooting in {sec}s... (Press Ctrl+C to cancel){RESET}"
                print(f"\n\n\n\t{msg}\n")
                time.sleep(1)
            clear_screen()
            subprocess.run(["systemctl", "reboot"], check=False)
            subprocess.run(["sudo", "reboot"], check=False)
            sys.exit(0)
        elif key in ('QUIT', 'CTRL_C', 'ESC'):
            inp.disable()
            exit_alt_screen()
            print(f"\n  {COLOR_GREEN}✓ Installation complete!{RESET} Please remember to reboot when ready.\n")
            sys.exit(0)

# ----------------- CLI Argument Parsing
if __name__ == "__main__":
    try:
        if "--preview-plan" in sys.argv:
            workspace_dir = os.path.dirname(os.path.realpath(__file__))
            plan = PlanConfig(workspace_dir)
            selected_idx = 0
            inp = InputManager()
            enter_alt_screen()
            inp.enable()
            try:
                while True:
                    term_w, term_h = shutil.get_terminal_size((80, 24))
                    render_plan_screen(plan, selected_idx, term_w, term_h)
                    key = inp.get_key(timeout=0.1)
                    if key == 'UP':
                        selected_idx = (selected_idx - 1) % len(plan.options)
                    elif key == 'DOWN':
                        selected_idx = (selected_idx + 1) % len(plan.options)
                    elif key in ('SPACE', 'RIGHT', 'LEFT'):
                        opt = plan.options[selected_idx]
                        if opt["type"] == "toggle":
                            opt["enabled"] = not opt["enabled"]
                        elif opt["type"] == "choice":
                            delta = 1 if key in ('SPACE', 'RIGHT') else -1
                            opt["index"] = (opt["index"] + delta) % len(opt["choices"])
                    elif key in ('ENTER', 'QUIT', 'CTRL_C', 'ESC'):
                        break
            finally:
                inp.disable()
                exit_alt_screen()
                print("\n  [Preview mode ended]\n")
                sys.exit(0)

        elif "--preview-progress" in sys.argv:
            workspace_dir = os.path.dirname(os.path.realpath(__file__))
            log_dir = os.path.join(workspace_dir, "Logs")
            os.makedirs(log_dir, exist_ok=True)
            log_file = os.path.join(log_dir, "preview.log")
            
            mock_steps = [
                {"title": "Configuring package repositories & build dependencies", "script": "", "cmd": "sudo pacman -Syu --needed base-devel git"},
                {"title": "Installing AUR helper (yay)", "script": "", "cmd": "git clone https://aur.archlinux.org/yay-git.git"},
                {"title": "Installing core Hyprland compositor & tools", "script": "", "cmd": "sudo pacman -S --noconfirm hyprland hyprlock hypridle"},
                {"title": "Installing system utility packages & libraries", "script": "", "cmd": "sudo pacman -S --noconfirm quickshell awww btop cliphist"},
                {"title": "Configuring desktop fonts", "script": "", "cmd": "sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd"},
                {"title": "Setting up SDDM display manager & theme", "script": "", "cmd": "sudo systemctl enable sddm.service"},
                {"title": "Configuring XDG desktop portal & screen sharing", "script": "", "cmd": "sudo pacman -S --noconfirm xdg-desktop-portal-hyprland"},
                {"title": "Installing visual themes & icons", "script": "", "cmd": "tar -xf themes.tar.gz -C ~/.themes"},
                {"title": "Configuring user login shell", "script": "", "cmd": "sudo usermod -s /bin/fish $USER"},
                {"title": "Applying hardware & battery profiles", "script": "", "cmd": "bash common/laptop.sh"},
                {"title": "Performing system verification check", "script": "", "cmd": "bash pacman-scripts/12-final.sh"},
                {"title": "Deploying Hyprconf (Quickshell) desktop suite", "script": "", "cmd": "chmod +x setup.sh && ./setup.sh"}
            ]
            
            enter_alt_screen()
            term_w, term_h = shutil.get_terminal_size((80, 24))
            exec_ui = ExecutionUI(mock_steps, log_file, term_w, term_h)

            stop_spinner = threading.Event()
            def spinner_loop():
                while not stop_spinner.is_set():
                    exec_ui.spinner_idx = (exec_ui.spinner_idx + 1) % len(exec_ui.spinner_frames)
                    exec_ui.render()
                    time.sleep(0.08)

            spin_thread = threading.Thread(target=spinner_loop, daemon=True)
            spin_thread.start()

            try:
                for idx, step in enumerate(mock_steps):
                    exec_ui.set_step(idx)
                    exec_ui.set_cmd(step["cmd"])
                    exec_ui.add_log_line(f"$ {step['cmd']}")
                    exec_ui.add_log_line(":: Synchronizing package databases...")
                    time.sleep(0.25)
                    exec_ui.add_log_line("resolving dependencies...")
                    exec_ui.add_log_line("looking for conflicting packages...")
                    time.sleep(0.3)
                    exec_ui.add_log_line(f"[ DONE ] - {step['title']} completed.")
                    time.sleep(0.2)

                stop_spinner.set()
                exec_ui.set_step(len(mock_steps))
                exec_ui.render()
                time.sleep(0.8)
            finally:
                stop_spinner.set()
                exit_alt_screen()
                print("\n  [Progress preview completed successfully!]\n")
                sys.exit(0)

        run_interactive_installer()
    except KeyboardInterrupt:
        exit_alt_screen()
        print(f"\n\n  {COLOR_RED}[!] Installation aborted by user.{RESET}\n")
        sys.exit(130)

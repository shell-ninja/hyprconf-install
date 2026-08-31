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
from datetime import datetime

# ----------------- ANSI Color Palette (Shell Ninja Cyber-Purple & Neon Cyan)
def rgb_fg(r, g, b):
    return f"\033[38;2;{r};{g};{b}m"

def rgb_bg(r, g, b):
    return f"\033[48;2;{r};{g};{b}m"

RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
ITALIC = "\033[3m"
CLEAR_LINE = "\033[K"

# Shell Ninja Cyber-Purple & Cyan Tokens
COLOR_ACCENT = rgb_fg(189, 147, 249)       # Electric Neon Purple (#bd93f9)
COLOR_ACCENT_ALT = rgb_fg(232, 121, 249)   # Vibrant Violet-Magenta (#e879f9)
COLOR_CYAN = rgb_fg(125, 207, 255)         # Neon Glacier Cyan (#7dcfff)
COLOR_GREEN = rgb_fg(166, 227, 161)        # Soft Emerald Green (#a6e3a1)
COLOR_RED = rgb_fg(247, 118, 142)          # Crimson error (#f7768e)
COLOR_YELLOW = rgb_fg(224, 175, 104)       # Warm gold (#e0af68)
COLOR_PURPLE = rgb_fg(203, 166, 247)       # Soft Lavender (#cba6f7)
COLOR_SLATE = rgb_fg(98, 114, 164)          # Dracula / Tokyo Night Slate (#6272a4)
COLOR_MUTED = rgb_fg(108, 112, 134)        # Dim grey (#6c7086)
COLOR_TEXT = rgb_fg(205, 214, 244)         # Crisp text (#cdd6f4)
COLOR_WHITE = rgb_fg(248, 248, 252)        # Bright white
COLOR_DARK_BAR = rgb_fg(49, 50, 68)        # Progress bar background

BORDER_COLOR = rgb_fg(86, 95, 137)         # Plan box border (#565f89)
ACCENT_BORDER = rgb_fg(189, 147, 249)      # Progress box border (#bd93f9)

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

def make_box_row(content_str, box_w, box_pad="", border_color=BORDER_COLOR, pad_left=2, pad_right=2):
    """
    Renders a pixel-perfect box line with exact character alignment.
    Total visible width = len(box_pad) + box_w
    """
    content_vis_len = visible_len(content_str)
    avail_w = (box_w - 2) - pad_left - pad_right
    fill_spaces = max(0, avail_w - content_vis_len)
    return (
        f"{box_pad}{border_color}│{RESET}"
        f"{' ' * pad_left}"
        f"{content_str}"
        f"{' ' * fill_spaces}"
        f"{' ' * pad_right}"
        f"{border_color}│{RESET}"
    )

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

def detect_snapshots():
    try:
        fstype = subprocess.check_output('findmnt -n -o FSTYPE / 2>/dev/null', shell=True).decode().strip()
        if 'btrfs' in fstype:
            return "btrfs root: snapper snapshots supported"
        elif 'zfs' in fstype:
            return "zfs root: zfs dataset snapshots supported"
    except Exception:
        pass
    return "configs saved with restore.sh before changes"

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
        self.gpu_name = detect_gpu()
        self.has_nvidia = is_nvidia_present()
        self.snapshots = detect_snapshots()
        self.keyboard = detect_keyboard()
        self.timezone = detect_timezone()
        self.is_dhaka_tz = (self.timezone == "Asia/Dhaka")

        self.options = [
            {
                "id": "sddm_theme",
                "name": "SDDM greeter theme",
                "desc": "points the SDDM login screen at the Hyprconf greeter",
                "type": "toggle",
                "enabled": True,
            },
            {
                "id": "bluetooth",
                "name": "Bluetooth support",
                "desc": "enables bluez daemon and bluetooth management tray applets",
                "type": "toggle",
                "enabled": True,
            },
            {
                "id": "shell",
                "name": "Login shell",
                "desc": "modern friendly interactive shell with hyprconf presets",
                "type": "choice",
                "choices": ["Bash", "Fish", "Zsh", "Skip"],
                "index": 0,
            },
            {
                "id": "browser",
                "name": "Web browser",
                "desc": "installs and configures your preferred modern web browser",
                "type": "choice",
                "choices": ["Brave", "Google_Chrome", "Zen Browser", "Firefox", "Chromium", "Vivaldi", "Skip"],
                "index": 0,
            },
            {
                "id": "nvidia",
                "name": "NVIDIA GPU drivers & patches",
                "desc": "enables proprietary nvidia drivers, env vars & Wayland flags",
                "type": "toggle",
                "enabled": self.has_nvidia,
            },
            {
                "id": "keyboard",
                "name": f"Keyboard layout ({self.keyboard})",
                "desc": f"sets keyboard layout in Hyprland configuration (current: {self.keyboard})",
                "type": "toggle",
                "enabled": True,
            }
        ]

        if self.is_dhaka_tz:
            self.options.append({
                "id": "openbangla",
                "name": "Fcitx5 & OpenBangla Keyboard",
                "desc": "Bangla typing support with OpenBangla Keyboard and Fcitx5 input method",
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

        with open(pkgman_cache, "w") as f:
            f.write(f"pkgman={self.pkgman}\n")

        with open(user_cache, "w") as f:
            f.write(f"setup_for_bluetooth='{'Y' if opt_map.get('bluetooth', {}).get('enabled') else 'N'}'\n")
            f.write("install_vs_code='N'\n")
            browser_choice = "Skip"
            if "browser" in opt_map:
                browser_choice = opt_map["browser"]["choices"][opt_map["browser"]["index"]]
            f.write(f"install_browser='{'N' if browser_choice == 'Skip' else 'Y'}'\n")
            f.write(f"have_nvidia='{'Y' if opt_map.get('nvidia', {}).get('enabled') else 'N'}'\n")
            f.write(f"install_sddm_theme='{'Y' if opt_map.get('sddm_theme', {}).get('enabled', True) else 'N'}'\n")
            f.write(f"install_openbangla='{'Y' if opt_map.get('openbangla', {}).get('enabled') else 'N'}'\n")

        with open(browser_cache, "w") as f:
            f.write(f"{browser_choice}\n")

        if self.pkgman == "pacman":
            aur_cache = os.path.join(cache_dir, "aur")
            aur_helper = shutil.which("yay") or shutil.which("paru")
            if aur_helper:
                with open(aur_cache, "w") as f:
                    f.write(f"{os.path.basename(aur_helper)}\n")
            elif not os.path.exists(aur_cache):
                with open(aur_cache, "w") as f:
                    f.write("yay-bin\n")

        shell_choice = opt_map.get("shell", {}).get("choices", ["Bash"])[opt_map.get("shell", {}).get("index", 0)]
        with open(shell_cache, "w") as f:
            f.write(f"install_fish='{'Y' if shell_choice == 'Fish' else 'N'}'\n")
            f.write(f"install_zsh='{'Y' if shell_choice == 'Zsh' else 'N'}'\n")
            f.write(f"setup_bash='{'Y' if shell_choice == 'Bash' else 'N'}'\n")

# ----------------- Plan UI Renderer
def render_plan_screen(plan, selected_idx, term_w, term_h):
    lines = []

    box_w = min(max(term_w - 4, 60), 74)
    box_pad = " " * max(0, (term_w - box_w) // 2)

    # Top Block Logo
    logo_l1 = "█░█ █▄█ █▀█ █▀█ █▀▀ █▀█ █▄░█ █▀▀"
    logo_l2 = "█▀█ ░█░ █▀▀ █▀▄ █▄▄ █▄█ █░▀█ █▀░"
    sub_title = "shell installer"
    plan_desc = f"Here is the plan for {COLOR_PURPLE}{plan.distro_id}{RESET}"

    l1_pad = " " * max(0, (term_w - len(logo_l1)) // 2)
    l2_pad = " " * max(0, (term_w - len(logo_l2)) // 2)
    sub_pad = " " * max(0, (term_w - len(sub_title)) // 2)
    plan_pad = " " * max(0, (term_w - visible_len(plan_desc)) // 2)

    lines.append("")
    lines.append(f"{l1_pad}{COLOR_ACCENT}{BOLD}{logo_l1}{RESET}")
    lines.append(f"{l2_pad}{COLOR_ACCENT_ALT}{BOLD}{logo_l2}{RESET}")
    lines.append(f"{sub_pad}{COLOR_MUTED}{sub_title}{RESET}")
    lines.append("")
    lines.append(f"{plan_pad}{COLOR_TEXT}{plan_desc}{RESET}")
    lines.append("")

    # Card 1: System Info Box
    top_border = f"{box_pad}{BORDER_COLOR}╭{'─' * (box_w - 2)}╮{RESET}"
    bot_border = f"{box_pad}{BORDER_COLOR}╰{'─' * (box_w - 2)}╯{RESET}"

    lines.append(top_border)

    def format_sys_content(label, val):
        max_val_w = box_w - 18
        disp_val = val if len(val) <= max_val_w else val[:max_val_w - 3] + "..."
        return f"{COLOR_CYAN}{label:<11}{RESET} {COLOR_TEXT}{disp_val}{RESET}"

    lines.append(make_box_row(format_sys_content("system", plan.distro_name), box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(format_sys_content("gpu", plan.gpu_name), box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(format_sys_content("login", "sddm.service"), box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(format_sys_content("snapshots", plan.snapshots), box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(format_sys_content("backup", "your touched configs are saved before changes"), box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(bot_border)
    lines.append("")

    # Card 2: Interactive Options Checklist Box
    lines.append(f"{box_pad}{BORDER_COLOR}╭{'─' * (box_w - 2)}╮{RESET}")

    # Title block centered inside the box
    title_line1 = f"{BOLD}{COLOR_ACCENT}Hyprconf Installation Script{RESET}"
    title_line2 = f"{COLOR_MUTED}by{RESET}"
    title_line3 = f"{BOLD}{COLOR_CYAN}Shell Ninja{RESET}"

    def center_in_box(content_str):
        """Center content_str within the inner box width."""
        inner_w = box_w - 2  # subtract left and right border chars
        vis = visible_len(content_str)
        total_pad = max(0, inner_w - vis)
        lpad = total_pad // 2
        rpad = total_pad - lpad
        return (
            f"{box_pad}{BORDER_COLOR}│{RESET}"
            f"{' ' * lpad}{content_str}{' ' * rpad}"
            f"{BORDER_COLOR}│{RESET}"
        )

    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(center_in_box(title_line1))
    lines.append(center_in_box(title_line2))
    lines.append(center_in_box(title_line3))
    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))
    # Divider
    sep = f"{BORDER_COLOR}{'─' * (box_w - 2)}{RESET}"
    lines.append(f"{box_pad}{BORDER_COLOR}│{RESET}{sep}{BORDER_COLOR}│{RESET}")
    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))

    for idx, opt in enumerate(plan.options):
        is_selected = (idx == selected_idx)
        bar = f"{COLOR_ACCENT}▍{RESET}" if is_selected else " "

        if opt["type"] == "toggle":
            if opt["enabled"]:
                status = f"{COLOR_GREEN}● on{RESET} "
            else:
                status = f"{COLOR_MUTED}○ off{RESET}"
            title_text = opt["name"]
        else:
            curr = opt["choices"][opt["index"]]
            if curr == "Skip":
                status = f"{COLOR_MUTED}○ off{RESET}"
                title_text = f"{opt['name']} {COLOR_MUTED}(skip){RESET}"
            else:
                status = f"{COLOR_GREEN}● on{RESET} "
                title_text = f"{opt['name']} {COLOR_ACCENT_ALT}({curr}){RESET}"

        if is_selected:
            title_styled = f"{BOLD}{COLOR_WHITE}{title_text}{RESET}"
        else:
            title_styled = f"{COLOR_TEXT}{title_text}{RESET}"

        row_content = f"{bar} {status}  {title_styled}"
        lines.append(make_box_row(row_content, box_w, box_pad, BORDER_COLOR, 1, 2))

        if is_selected:
            desc_text = opt['desc']
            max_desc_w = box_w - 12
            if len(desc_text) > max_desc_w:
                desc_text = desc_text[:max_desc_w - 3] + "..."
            desc_content = f"     {COLOR_MUTED}{ITALIC}{desc_text}{RESET}"
            lines.append(make_box_row(desc_content, box_w, box_pad, BORDER_COLOR, 1, 2))

    lines.append(f"{box_pad}{BORDER_COLOR}╰{'─' * (box_w - 2)}╯{RESET}")
    lines.append("")

    # Footer navigation keys
    footer = (
        f"{COLOR_ACCENT}↑↓{RESET} {COLOR_MUTED}move{RESET}   ·   "
        f"{COLOR_ACCENT}space{RESET} {COLOR_MUTED}toggle{RESET}   ·   "
        f"{COLOR_ACCENT}enter{RESET} {COLOR_MUTED}install{RESET}   ·   "
        f"{COLOR_ACCENT}q{RESET} {COLOR_MUTED}quit{RESET}"
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

            box_w = min(max(term_w - 4, 60), 74)
            box_pad = " " * max(0, (term_w - box_w) // 2)

            lines = []
            # Top Border
            lines.append(f"{box_pad}{ACCENT_BORDER}╭{'─' * (box_w - 2)}╮{RESET}")

            # Header inside box
            header_title = f"{BOLD}{COLOR_ACCENT}Installing the Hyprland desktop{RESET}"
            lines.append(make_box_row(header_title, box_w, box_pad, ACCENT_BORDER, 2, 2))
            lines.append(make_box_row("", box_w, box_pad, ACCENT_BORDER, 2, 2))

            # Progress Bar Calculation
            total_steps = max(len(self.steps), 1)
            completed_count = min(self.current_step_idx, total_steps)
            fraction_str = f"{completed_count}/{total_steps}"

            # Exact bar width
            inner_content_w = (box_w - 2) - 4
            avail_bar_w = inner_content_w - len(fraction_str) - 4
            bar_w = min(max(avail_bar_w, 20), 44)
            filled_len = int((completed_count / total_steps) * bar_w)
            unfilled_len = bar_w - filled_len

            bar_str = (
                f"{COLOR_ACCENT}{'█' * filled_len}{RESET}"
                f"{COLOR_DARK_BAR}{'░' * unfilled_len}{RESET}"
            )
            prog_content = f"{bar_str}  {COLOR_WHITE}{BOLD}{fraction_str}{RESET}"
            lines.append(make_box_row(prog_content, box_w, box_pad, ACCENT_BORDER, 2, 2))
            lines.append(make_box_row("", box_w, box_pad, ACCENT_BORDER, 2, 2))

            # Step Checklist
            max_visible_steps = max(min(len(self.steps), term_h - 16), 5)
            start_s = 0
            if len(self.steps) > max_visible_steps:
                start_s = max(0, min(self.current_step_idx - 2, len(self.steps) - max_visible_steps))
            end_s = min(start_s + max_visible_steps, len(self.steps))

            for i in range(start_s, end_s):
                step = self.steps[i]
                max_step_title_w = box_w - 10
                st_title = step['title']
                if len(st_title) > max_step_title_w:
                    st_title = st_title[:max_step_title_w - 3] + "..."

                if i < self.current_step_idx:
                    icon = f"{COLOR_GREEN}✓{RESET}"
                    label = f"{COLOR_TEXT}{st_title}{RESET}"
                elif i == self.current_step_idx:
                    spin = self.spinner_frames[self.spinner_idx % len(self.spinner_frames)]
                    icon = f"{COLOR_ACCENT_ALT}{BOLD}{spin}{RESET}"
                    label = f"{BOLD}{COLOR_WHITE}{st_title}{RESET}"
                else:
                    icon = f"{COLOR_MUTED}·{RESET}"
                    label = f"{COLOR_MUTED}{st_title}{RESET}"

                s_content = f"{icon} {label}"
                lines.append(make_box_row(s_content, box_w, box_pad, ACCENT_BORDER, 2, 2))

            lines.append(make_box_row("", box_w, box_pad, ACCENT_BORDER, 2, 2))
            
            # Sub-separator line (aligned perfectly)
            sep_str = f"{BORDER_COLOR}{'─' * (box_w - 2)}{RESET}"
            lines.append(f"{box_pad}{ACCENT_BORDER}│{RESET}{sep_str}{ACCENT_BORDER}│{RESET}")

            # Sub-Terminal Window
            cmd_display = self.current_cmd if self.current_cmd else "running tasks..."
            max_cmd_w = box_w - 10
            if len(cmd_display) > max_cmd_w:
                cmd_display = cmd_display[:max_cmd_w - 3] + "..."
            cmd_line = f"{COLOR_CYAN}${RESET} {COLOR_MUTED}{cmd_display}{RESET}"
            lines.append(make_box_row(cmd_line, box_w, box_pad, ACCENT_BORDER, 2, 2))

            sub_lines = self.log_lines[-5:] if self.log_lines else []
            while len(sub_lines) < 5:
                sub_lines.append("")

            for l in sub_lines:
                max_log_w = box_w - 10
                disp_l = l if len(l) <= max_log_w else l[:max_log_w - 3] + "..."
                l_content = f"{COLOR_MUTED}{disp_l}{RESET}"
                lines.append(make_box_row(l_content, box_w, box_pad, ACCENT_BORDER, 4, 2))

            # Bottom Border
            lines.append(f"{box_pad}{ACCENT_BORDER}╰{'─' * (box_w - 2)}╯{RESET}")
            lines.append("")

            # Log path truncation if too long
            max_log_w = term_w - 34
            disp_log = self.log_path if len(self.log_path) <= max_log_w else "..." + self.log_path[-(max_log_w - 3):]
            footer_text = f"{COLOR_MUTED}installing, do not interrupt  ·  log: {disp_log}{RESET}"
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

# ----------------- Celebratory Finish & Reboot Screen
def render_finish_screen(plan, term_w, term_h):
    box_w = min(max(term_w - 4, 60), 74)
    box_pad = " " * max(0, (term_w - box_w) // 2)

    lines = []
    lines.append("")
    lines.append(f"{box_pad}{BORDER_COLOR}╭{'─' * (box_w - 2)}╮{RESET}")

    title = f"{COLOR_GREEN}{BOLD}✦ HYPRLAND & HYPRCONF INSTALLED SUCCESSFULLY ✦{RESET}"
    avail_w = (box_w - 2) - 4
    t_pad_left = max(0, (avail_w - visible_len(title)) // 2) + 2
    lines.append(make_box_row(title, box_w, box_pad, BORDER_COLOR, t_pad_left, 2))
    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))

    lines.append(make_box_row(f"{COLOR_TEXT}All selected packages, dotfiles, themes, and services are configured.{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row(f"{COLOR_MUTED}A system reboot is required to start your new Hyprland session.{RESET}", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(make_box_row("", box_w, box_pad, BORDER_COLOR, 2, 2))
    lines.append(f"{box_pad}{BORDER_COLOR}╰{'─' * (box_w - 2)}╯{RESET}")
    lines.append("")

    footer = (
        f"{COLOR_ACCENT}enter{RESET} {COLOR_WHITE}{BOLD}reboot now{RESET}   ·   "
        f"{COLOR_ACCENT}q / esc{RESET} {COLOR_MUTED}exit to terminal{RESET}"
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
    print(f"\n  {COLOR_ACCENT}✦ Hyprconf Installer{RESET} - {COLOR_MUTED}Authenticating administrative access...{RESET}\n")
    sudo_res = subprocess.run(["sudo", "-v"])
    if sudo_res.returncode != 0:
        print(f"\n  {COLOR_RED}[!] Sudo authentication failed. Exiting.{RESET}\n")
        sys.exit(1)

    stop_sudo = threading.Event()
    sudo_thread = threading.Thread(target=sudo_keepalive, args=(stop_sudo,), daemon=True)
    sudo_thread.start()

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
                    f.write("yay-bin\n")
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

    # Step 5b: SDDM theme (SilentSDDM) — runs as a dedicated step when enabled
    if opt_map.get("sddm_theme", {}).get("enabled", True):
        steps.append({
            "title": "Installing SilentSDDM greeter theme & fonts",
            "script": os.path.join(common_dir, "sddm_theme.sh"),
            "cmd": f"bash {common_dir}/sddm_theme.sh"
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
        "title": "Deploying GTK, Qt, Kvantum & icon themes",
        "script": os.path.join(common_dir, "themes.sh"),
        "cmd": f"bash {common_dir}/themes.sh"
    })

    # Step 13: Hyprconf dotfiles  (interactive — full terminal handoff)
    steps.append({
        "title": "Deploying Hyprconf dotfiles & wallpapers",
        "script": os.path.join(common_dir, "hyprconf.sh"),
        "cmd": f"bash {common_dir}/hyprconf.sh",
        "interactive": True,       # TUI will pause and hand terminal to setup.sh
    })

    # Step 14: Hardware Profile (Laptop vs Desktop)
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

    # Step 15: Final Checkup
    steps.append({
        "title": "Running final system verification & health check",
        "script": os.path.join(scripts_dir, "12-final.sh"),
        "cmd": f"bash {scripts_dir}/12-final.sh"
    })

    # 4. Live Progress Execution Loop
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
            # 1. Freeze spinner, stop the TUI
            stop_spinner.set()
            spin_thread.join(timeout=0.5)
            inp.disable()
            exit_alt_screen()

            # 2. Print a styled interstitial screen in normal terminal mode
            os.system("clear")
            print()
            print(f"  {COLOR_ACCENT}{BOLD}{'─' * 64}{RESET}")
            print(f"  {COLOR_ACCENT}{BOLD}  ✦  INTERACTIVE SETUP  ─  Hyprconf Dotfiles{RESET}")
            print(f"  {COLOR_ACCENT}{BOLD}{'─' * 64}{RESET}")
            print()
            print(f"  {COLOR_TEXT}The TUI installer is handing control to the Hyprconf setup\n"
                  f"  script. You can now interact with all prompts directly:\n")
            print(f"  {COLOR_ACCENT}▸{RESET} {COLOR_TEXT}Choose your bar layout (Waybar){RESET}")
            print(f"  {COLOR_ACCENT}▸{RESET} {COLOR_TEXT}Choose your lockscreen style (Hyprlock){RESET}")
            print(f"  {COLOR_ACCENT}▸{RESET} {COLOR_TEXT}Opt in/out of extra wallpaper download{RESET}")
            print(f"  {COLOR_ACCENT}▸{RESET} {COLOR_TEXT}Backup existing configs as you prefer{RESET}")
            print()
            print(f"  {COLOR_MUTED}When the setup script finishes, the TUI will automatically resume.{RESET}")
            print(f"  {COLOR_ACCENT}{BOLD}{'─' * 64}{RESET}")
            print()
            input(f"  {COLOR_CYAN}Press Enter to launch the Hyprconf setup script...{RESET} ")
            print()

            # 3. Run the script with FULL terminal (stdin, stdout, stderr all native)
            env_interactive = os.environ.copy()
            # Remove TUI suppression flags so setup.sh gets real gum menus
            env_interactive.pop("HYPRCONF_TUI", None)
            env_interactive.pop("DEBIAN_FRONTEND", None)
            # Signal common/hyprconf.sh to skip the gum shim & pipe — full TTY handoff
            env_interactive["HYPRCONF_INTERACTIVE"] = "1"

            ret = subprocess.run([script_path], env=env_interactive)

            # 4. Log the outcome
            with open(log_file, "a") as lf:
                outcome = "OK" if ret.returncode == 0 else f"EXIT_CODE={ret.returncode}"
                lf.write(f"[INTERACTIVE] {step['title']} completed — {outcome}\n")

            # 5. Resume-prompt before returning to the TUI
            print()
            print(f"  {COLOR_ACCENT}{BOLD}{'─' * 64}{RESET}")
            if ret.returncode == 0:
                print(f"  {COLOR_GREEN}✓  Hyprconf setup completed successfully!{RESET}")
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
            exec_ui.add_log_line("Hyprconf dotfiles configured — continuing installation...")
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

    # 6. Celebratory Finish Screen
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
                {"title": "Retiring previous distro's package sources", "script": "", "cmd": "sudo pacman -Syu --noconfirm"},
                {"title": "Updating the system databases", "script": "", "cmd": "sudo pacman -Syu --needed base-devel git"},
                {"title": "Installing installer tools (git, build tools)", "script": "", "cmd": "git clone https://aur.archlinux.org/yay.git"},
                {"title": "Fetching the Hyprconf payload", "script": "", "cmd": "curl -L https://github.com/shell-ninja/hyprconf.zip"},
                {"title": "Backing up your existing configs", "script": "", "cmd": "cp -r ~/.config/hypr ~/.config/hypr.backup"},
                {"title": "Installing the Hyprland desktop", "script": "", "cmd": "sudo pacman -S --noconfirm hyprland hyprlock hypridle"},
                {"title": "Setting up GPU drivers & Wayland flags", "script": "", "cmd": "sudo pacman -S --noconfirm vulkan-intel"},
                {"title": "Wiring the login session (SDDM, network)", "script": "", "cmd": "sudo systemctl enable sddm.service"},
                {"title": "Laying down your Hyprconf configs", "script": "", "cmd": "chmod +x setup.sh && ./setup.sh"},
                {"title": "Deploying GTK & icon themes", "script": "", "cmd": "tar -xf themes.tar.gz -C ~/.themes"},
                {"title": "Configuring your login shell with Bash", "script": "", "cmd": "chsh -s /bin/bash"},
                {"title": "Verifying the installation health", "script": "", "cmd": "fastfetch && sleep 1"}
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

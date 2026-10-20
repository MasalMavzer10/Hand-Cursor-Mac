# Hand + Head/Mouth Cursor Studio

I built this project to try a different way of controlling a cursor with a webcam. My hand moves the pointer, a brief mouth opening clicks, a thumb-and-index pinch drags, and head movement scrolls. The macOS app controls the desktop pointer; the browser studio gives you a place to try the gestures on a simulated desktop.

The project uses OpenCV and MediaPipe for tracking. The macOS setup is written for macOS 11+ and Python 3.9–3.11. You will need a webcam, and macOS will ask for Camera and Accessibility access when you run the desktop controller.

## Contents

1. [How the project evolved](#how-the-project-evolved)
2. [Controls](#controls)
3. [How the tracking works](#how-the-tracking-works)
4. [Repository layout](#repository-layout)
5. [Run it on macOS](#run-it-on-macos)
6. [Try the browser studio](#try-the-browser-studio)
7. [Self-test and CI](#self-test-and-ci)
8. [Privacy and safety](#privacy-and-safety)
9. [License](#license)

## How the project evolved

### First pass: one-handed control

I started with a six-stage version of the desktop controller:

| Stage | What I added |
| --- | --- |
| A | OpenCV camera capture, MediaPipe's 21 hand landmarks, index-finger tracking, and a `NO HAND` state that stops pointer updates when tracking is lost. |
| B | A mirrored camera view, screen-coordinate mapping, and an active region with 18% margins so the hand does not have to reach the edges of the frame. |
| C | macOS pointer events through Quartz (`CGEventPost` / `kCGHIDEventTap`), a `pynput` fallback, a three-second startup countdown, and pause controls. |
| D | Thumb-to-index pinch detection using landmarks `4` and `8`, normalized by the distance from landmarks `0` to `9`. The first click/drag version used hysteresis: enter below `0.28`, exit above `0.40`. |
| E | Two-finger scrolling based on an upright index and middle finger, folded ring and little fingers, and vertical movement from an anchor point. |
| F | A four-point calibration flow and an OpenCV heads-up display. |

That version showed me a few problems. Pinching to click could move the fingertip just as the pointer reached a small target. A short pinch and the start of a drag were also hard to tell apart. Holding two fingers up to scroll was uncomfortable for longer stretches. Those observations led me to split the actions across hand and face gestures.

### Current approach: separate gestures for separate actions

MediaPipe Hands tracks the pointer and pinch. MediaPipe FaceMesh tracks the mouth and head. The input path is:

```text
Webcam frame
├── Hand landmarks (21 points)
│   ├── Knuckle/tip blend → pointer movement
│   └── Thumb/index distance → drag and drop
└── Face landmarks (468 points)
    ├── Inner-lip distance → left click
    └── Nose position relative to eyes → scrolling
```

I also changed the pointer response curve after noticing that an exponent below `1` enlarged small movements near the center. The current fine-aim curve uses an exponent of `1.35` instead.

### Browser studio

`index.html` contains a browser version for trying the controls on a simulated desktop. It loads `@mediapipe/hands` and `@mediapipe/face_mesh` through a CDN and includes corner targets, buttons with hit counters, draggable cards, a drop folder, and a scrollable pane. If you do not want to use a camera, the simulator has gesture buttons, sliders, and pointer-steering controls. The studio also has buttons to download `hand_cursor_mac.py` and `run_mac.command`.

The browser studio controls its own demo area; use the Python app to control the macOS desktop pointer.

## Controls

| Action | Gesture or key | Settings described in this version |
| --- | --- | --- |
| Move pointer | Move your hand inside the active camera region | Anchor: 70% index knuckle (`lm[5]`) + 30% index tip (`lm[8]`); adaptive smoothing factor from `0.16` to `0.78` |
| Left click | Briefly open your mouth | Mouth aspect ratio (MAR) enters at `≥ 0.26`, resets at `≤ 0.16`; 45 ms debounce and 320 ms cooldown |
| Drag and drop | Pinch thumb and index finger, then release | Drag starts when the normalized distance is `< 0.26` for more than 180 ms; release is `> 0.38` |
| Scroll up / down | Tilt your head up / down | Head-position change outside a `±0.035` neutral band; press `N` to recenter |
| Pause / resume | `Space`, `P`, or global `Cmd+Shift+P` | Pausing releases an active drag and stops pointer updates |
| Calibrate | `C` or the calibration button | Four points set the active tracking area |

Gesture detection depends on camera position, lighting, and how much of your hand and face stay in frame. If the pointer or gestures feel off, recalibrate and adjust the available controls in the app or studio.

## How the tracking works

### Pointer anchor

Rather than follow only the index fingertip, I blend it with the index knuckle (the MCP joint):

$$\mathbf{P}_{\text{anchor}} = 0.70\mathbf{L}_5 + 0.30\mathbf{L}_8$$

This gives the pointer a less fingertip-dependent target when the finger bends or pinches.

### Adaptive pointer smoothing

The smoothing factor increases with movement distance. In the formulas below, $(x_{t-1}, y_{t-1})$ is the previous smoothed pointer position and $(x_{\text{target}}, y_{\text{target}})$ is the new mapped target:

$$\text{dist} = \sqrt{(x_{\text{target}}-x_{t-1})^2 + (y_{\text{target}}-y_{t-1})^2}$$

$$v_{\text{norm}} = \min\left(1, \frac{\text{dist}}{110}\right)$$

$$\alpha = 0.16 + v_{\text{norm}}(0.78-0.16)$$

$$x_t = x_{t-1} + \alpha(x_{\text{target}}-x_{t-1}), \qquad y_t = y_{t-1} + \alpha(y_{\text{target}}-y_{t-1})$$

This is a velocity-adaptive exponential smoothing step: smaller movements get more smoothing, while larger movements follow the target more quickly.

For fine aiming, the response curve is:

$$\text{output} = \operatorname{sign}(c_x)|c_x|^{1.35}$$

The previous version used $|c_x|^{1/\gamma}$ with $\gamma=1.15$ (an exponent of about `0.87`). An exponent below `1` increases the response to very small nonzero inputs; `1.35` reduces it. This curve does not create a literal dead zone.

### Mouth click

I use the vertical distance between the inner lips, divided by mouth width:

$$\text{MAR} = \frac{\|\mathbf{L}_{14}-\mathbf{L}_{13}\|_2}{\|\mathbf{L}_{308}-\mathbf{L}_{78}\|_2}$$

The separate enter and reset thresholds help prevent repeated clicks while the mouth stays open.

### Head-controlled scrolling

The scroll signal compares nose height with eye height and normalizes it by face height:

$$y_{\text{eyes}} = \frac{y_{33}+y_{263}}{2}, \qquad h_{\text{face}} = |y_{152}-y_{10}|$$

$$r_{\text{pitch}} = 0.36 - \frac{y_{\text{nose}}-y_{\text{eyes}}}{h_{\text{face}}}, \qquad \Delta r = r_{\text{pitch}}-r_{\text{neutral}}$$

Outside the neutral band, the documented scroll response is:

$$\text{scroll speed} = \operatorname{sign}(\Delta r)(|\Delta r|-\delta_{\text{deadzone}})K_{\text{scroll}}$$

The scroll expression applies when $|\Delta r|>\delta_{\text{deadzone}}$; inside the band, scroll speed is zero. This is a normalized head-position estimate, not a measured angle in degrees. Press `N` to set a new neutral position.

## Repository layout

```text
.
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions self-test
├── .gitignore
├── LICENSE
├── README.md
├── hand_cursor_mac.py          # macOS desktop controller
├── index.html                  # Browser studio and simulated desktop
├── requirements.txt            # Python dependencies
└── run_mac.command             # macOS launcher
```

## Run it on macOS

### Option A: Finder launcher

Clone or download the repository:

```bash
git clone https://github.com/MasalMavzer10/Hand-Cursor-Mac.git
cd Hand-Cursor-Mac
```

Then double-click `run_mac.command` in Finder. The launcher is set up to create a virtual environment, install the Python dependencies with the UTF-8 and `--no-compile` settings below, and start the app.

### Option B: Terminal

```bash
git clone https://github.com/MasalMavzer10/Hand-Cursor-Mac.git
cd Hand-Cursor-Mac

python3 -m venv .venv
source .venv/bin/activate

export PYTHONIOENCODING=utf-8
python3 -m pip install --upgrade pip
python3 -m pip install --no-compile -r requirements.txt

# Check tracking without moving the desktop pointer.
python3 hand_cursor_mac.py --preview-only

# Start desktop pointer control.
python3 hand_cursor_mac.py
```

The UTF-8 setting and `--no-compile` option address a MediaPipe installation error I encountered with a macOS developer-tools Python 3.9 setup. The error included an unexpected non-ASCII character while compiling a package test file.

For desktop control, give the app you launch Python from access under **System Settings → Privacy & Security → Camera** and **Accessibility**. That may be Terminal or your IDE, depending on how you run it.

## Try the browser studio

Open `index.html` locally, or host the repository through GitHub Pages:

1. Open the repository's **Settings → Pages** page.
2. Select the `main` (or `master`) branch and `/ (root)` as the publishing source, then save.
3. After GitHub finishes publishing, the expected project URL is [masalmavzer10.github.io/Hand-Cursor-Mac](https://masalmavzer10.github.io/Hand-Cursor-Mac/).

The browser needs camera permission for live gesture tracking. It also needs internet access to load the MediaPipe packages from the CDN. You can use the simulator controls without a camera.

## Self-test and CI

The desktop script includes a self-test mode that does not need a webcam or graphical desktop:

```bash
python3 hand_cursor_mac.py --self-test
```

The tests described for this project cover stopping pointer updates when the hand disappears, screen mapping and smoothing, mouth clicks, pinch dragging, and head scrolling. The repository layout includes `.github/workflows/ci.yml` for running the self-test on pushes and pull requests on Ubuntu and macOS.

## Privacy and safety

The Python app processes camera input locally for pointer control. The browser studio runs tracking in your browser, but downloads its MediaPipe packages from a CDN, so loading it uses a network connection.

Use `--preview-only` to check camera tracking before enabling desktop control. `Space`, `P`, and `Cmd+Shift+P` are the documented pause controls, and losing hand tracking stops pointer updates.

## License

The project is distributed under the MIT License. See [LICENSE](LICENSE).

Local Hand + Head/Mouth Cursor for macOS (v2.0)
================================================

HOW TO RUN ON YOUR MAC:
1. Unzip this folder (`hand_cursor_mac_package.zip`).
2. Open the macOS Terminal app, type `cd ` (with a space), drag the unzipped
   folder into the Terminal window, and press Enter.
3. Run these two commands:
     pip3 install -r requirements.txt
     python3 hand_cursor_mac.py

   (Or simply run `bash run_mac.command` to auto-create a virtual environment
   and start the app.)

CONTROLS:
- Move Cursor : Move your hand inside the active box (uses stabilized knuckle+tip anchor).
- Left Click  : Open your mouth briefly (your hand stays completely still!).
- Drag & Drop : Pinch thumb + index finger and hold to drag; release to drop.
- Scroll Up/Dn: Tilt/move your head UP to scroll up, or DOWN to scroll down.
- Re-Center   : Press [N] to re-center your neutral head angle.
- Pause/Resume: Press [SPACE] or [P] (or Cmd+Shift+P globally).
- Quit        : Press [Q] or [ESC].

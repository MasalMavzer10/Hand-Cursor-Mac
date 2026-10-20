# Hand-Cursor-Mac
It is a cursor which functions as a mouse for macOS (Locally Runs Hand + Head/Mouth Cursor) with Gemini 4 Argon
-----------------------------------------------------------------------

How to run on your mac:
1. Download the folder (`hand_cursor_mac_package`).
2. Open the macOS Terminal app, type `cd ` (with a space), drag the folder into the Terminal window, and press Enter.
3. Run these two commands:
     `pip3 install -r requirements.txt`
     `python3 hand_cursor_mac.py`

   (Or simply run `python3 -m venv venv` and `source venv/bin/activate` to auto-create a virtual environment
   and run the command `python3 hand_cursor_mac.py`)

Controls:
- Move Cursor : Move your hand inside the active box (uses stabilized knuckle+tip anchor).
- Left Click  : Open your mouth briefly (your hand stays completely still!).
- Drag & Drop : Pinch thumb + index finger and hold to drag; release to drop.
- Scroll Up/Dn: Tilt/move your head UP to scroll up, or DOWN to scroll down.
- Re-Center   : Press [N] to re-center your neutral head angle.
- Pause/Resume: Press [SPACE] or [P] (or Cmd+Shift+P globally).
- Quit        : Press [Q] or [ESC].

*Recommendations:*
  1. Please check if you're using python 3.9 ~ 3.12 because MediaPipe officially supports Python versions up to python 3.12
  2. If you don't have OpenCV and MediaPipe on your mac run:
      `pip install opencv-python`
      `pip install mediapipe`
  3. It is extremely important to make the virtual environment created to be activated
  4. The macOS does not allow the Python scripts or the terminal to control the system (moderate/keyboard) from the outside due to security issues. In order for the program to work, you need to give accessibility to the terminal 

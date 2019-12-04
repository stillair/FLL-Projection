+-------------+
| Black Spout |
+-------------+

Black Spout allows any application with Spout Receiver capability to receive video from a Blackmagic capture device.

To use, simply run the Black Spout executable (BlackSpout.exe) and follow the prompts.  In your Spout Receiver application, select Black Spout as your Spout Sender.


Command-line parameters
-----------------------

BlackSpout.exe accepts command-line parameters (optional).

Usage is as follows:
BlackSpout -input # -mode # -width # -height # -x # -y # -name "abc" -device #

For example:
BlackSpout -input 1 -mode 15 -width 640 -height 360 -x 50 -y 50 -name "My HDMI Capture" -device 0
This results in HDMI input, HD 720p 60 mode, using first available Blackmagic device.

The width and height parameters affect only the window size, not the capture size.  Capture size is always the native resolution (i.e., 1280x720 for 720p mode).

The x and y parameters determine the window position relative to the top-left corner of the screen.

To determine the input and mode parameters for your setup, run BlackSpout.exe with no parameters, and follow the prompts.  You can then create a batch file to automate your setup; see the included BS.bat as an example.

All, some, or none of the command-line parameters can be used.  The device parameter defaults to 0, and is not needed if only one Blackmagic device is connected to the system.


More information
----------------

For the latest information about Black Spout, visit the Magic Music Visuals forums:
http://magicmusicvisuals.com/forums/viewtopic.php?f=6&t=201

For the latest information about Spout, visit the Spout web site:
http://spout.zeal.co


---

Black Spout v0.11 - Copyright (c) 2012-2014 Color & Music, LLC.  All rights reserved.

By using Black Spout, you agree to the following terms:
Black Spout is provided "as is" without any express or implied warranty of any kind, oral or written, including warranties of merchantability, fitness for any particular purpose, non-infringement, information accuracy, integration, interoperability, or quiet enjoyment.  In no event shall Color & Music, LLC or its suppliers be liable for any damages whatsoever (including, without limitation, damages for loss of profits, business interruption, loss of information, or physical damage to hardware or storage media) arising out of the use of, misuse of, or inability to use Black Spout, your reliance on any functionality in Black Spout, or from the modification, alteration or complete discontinuance of Black Spout, even if Color & Music, LLC has been advised of the possibility of such damages.
{
  # Use only the supported nix-darwin trackpad options
  system.defaults.trackpad = {
    # Enable tap to click
    Clicking = true;
    # Enable three finger drag
    TrackpadThreeFingerDrag = true;
    # Enable right click with two fingers
    TrackpadRightClick = true;
  };

  system.defaults.CustomSystemPreferences = {
    # Trackpad settings that need custom preferences
    "com.apple.AppleMultitouchTrackpad" = {
      # Basic settings
      Clicking = true;
      DragLock = false;
      Dragging = false;
      # Corner settings
      TrackpadCornerSecondaryClick = false;
      # Gesture settings
      TrackpadPinch = true;
      TrackpadRotate = true;
      TrackpadScroll = true;
      TrackpadFourFingerVertSwipeGesture = 2;  # Mission Control
      TrackpadFourFingerHorizSwipeGesture = 2; # App Expose
      TrackpadThreeFingerVertSwipeGesture = 2; # App Expose
      TrackpadThreeFingerHorizSwipeGesture = 2; # Swipe between pages
      TrackpadFiveFingerPinchGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
      TrackpadThreeFingerDrag = true;
      TrackpadThreeFingerTapGesture = false;
      TrackpadTwoFingerDoubleTapGesture = true;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      # Scrolling
      TrackpadHorizScroll = true;
      TrackpadMomentumScroll = true;
      # Other settings
      USBMouseStopsTrackpad = false;
      TrackpadHandResting = true;
      TrackpadRightClick = true;
      # Technical settings
      ActuateDetents = true;
      FirstClickThreshold = true;
      SecondClickThreshold = true;
      ForceSuppressed = false;
      UserPreferences = true;
      version = 12;
    };

    # Bluetooth trackpad settings
    "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
      Clicking = true;
      DragLock = false;
      Dragging = false;
      TrackpadCornerSecondaryClick = false;
      TrackpadRightClick = true;
      TrackpadScroll = true;
      TrackpadPinch = true;
      TrackpadRotate = true;
      TrackpadMomentumScroll = true;
      TrackpadThreeFingerDrag = true;
      TrackpadThreeFingerTapGesture = false;
      TrackpadThreeFingerVertSwipeGesture = 2;
      TrackpadThreeFingerHorizSwipeGesture = 2;
      TrackpadTwoFingerDoubleTapGesture = true;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      TrackpadFourFingerVertSwipeGesture = 2;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
      TrackpadFiveFingerPinchGesture = 2;
      TrackpadHandResting = true;
      USBMouseStopsTrackpad = false;
      UserPreferences = true;
      version = 5;
    };

    # Mouse settings
    "com.apple.AppleMultitouchMouse" = {
      MouseButtonMode = "OneButton";
      MouseButtonDivision = 55;
      MouseHorizontalScroll = true;
      MouseVerticalScroll = true;
      MouseMomentumScroll = true;
      MouseOneFingerDoubleTapGesture = false;
      MouseTwoFingerDoubleTapGesture = 3;
      MouseTwoFingerHorizSwipeGesture = 2;
      UserPreferences = true;
      version = true;
    };

    # Bluetooth mouse settings
    "com.apple.driver.AppleBluetoothMultitouch.mouse" = {
      MouseButtonMode = "OneButton";
      MouseButtonDivision = 55;
      MouseHorizontalScroll = true;
      MouseVerticalScroll = true;
      MouseMomentumScroll = true;
      MouseOneFingerDoubleTapGesture = false;
      MouseTwoFingerDoubleTapGesture = 3;
      MouseTwoFingerHorizSwipeGesture = 2;
      UserPreferences = true;
    };

    # HID Mouse settings (for generic USB mice)
    "com.apple.driver.AppleHIDMouse" = {
      Button1 = 1;
      Button2 = 2;
      Button3 = 0;
      Button4 = 0;
      Button4Click = 0;
      Button4Force = 0;
      ButtonDominance = 1;
      ScrollH = 1;
      ScrollS = 4;
      ScrollSSize = 30;
      ScrollV = 1;
    };
  };
}

{
  system.defaults.trackpad = {
    # Enable tap to click
    Clicking = true;
    # Enable three finger drag
    TrackpadThreeFingerDrag = true;
    # Enable right click with two fingers
    TrackpadRightClick = true;
    # Enable natural scrolling
    TrackpadScroll = true;
  };

  system.defaults.CustomSystemPreferences = {
    # Trackpad settings that need custom preferences
    "com.apple.AppleMultitouchTrackpad" = {
      # Enable corner secondary click
      TrackpadCornerSecondaryClick = false;
      # Enable pinch to zoom
      TrackpadPinch = true;
      # Enable rotation gestures
      TrackpadRotate = true;
      # Gesture settings
      TrackpadFourFingerVertSwipeGesture = 2;  # Mission Control
      TrackpadFourFingerHorizSwipeGesture = 2; # App Expose
      TrackpadThreeFingerVertSwipeGesture = 2; # App Expose
      TrackpadThreeFingerHorizSwipeGesture = 2; # Swipe between pages
      TrackpadFiveFingerPinchGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
      # Don't stop trackpad when USB mouse is connected
      USBMouseStopsTrackpad = false;
      # Enable momentum scrolling
      TrackpadMomentumScroll = true;
      # Version info
      version = 12;
      UserPreferences = true;
    };

    # Bluetooth trackpad settings
    "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadScroll = true;
      TrackpadPinch = true;
      TrackpadRotate = true;
      TrackpadMomentumScroll = true;
      TrackpadThreeFingerDrag = true;
      TrackpadCornerSecondaryClick = false;
      USBMouseStopsTrackpad = false;
      UserPreferences = true;
      version = 5;
    };

    # Mouse settings
    "com.apple.AppleMultitouchMouse" = {
      MouseButtonMode = "OneButton";
      MouseHorizontalScroll = true;
      MouseVerticalScroll = true;
      MouseMomentumScroll = true;
      MouseTwoFingerDoubleTapGesture = 3;
      MouseTwoFingerHorizSwipeGesture = 2;
      MouseButtonDivision = 55;
      UserPreferences = true;
      version = true;
    };

    # Bluetooth mouse settings
    "com.apple.driver.AppleBluetoothMultitouch.mouse" = {
      MouseButtonMode = "OneButton";
      MouseHorizontalScroll = true;
      MouseVerticalScroll = true;
      MouseMomentumScroll = true;
      MouseTwoFingerDoubleTapGesture = 3;
      MouseTwoFingerHorizSwipeGesture = 2;
      MouseButtonDivision = 55;
      UserPreferences = true;
    };
  };
}

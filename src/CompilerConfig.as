CONFIG const fakeReleaseMode:Boolean = false;
CONFIG const debugModeInRelease:Boolean = false;
CONFIG const isDebugMode:Boolean = CONFIG::debugModeInRelease || (CONFIG::debug && !CONFIG::fakeReleaseMode);
CONFIG const isReleaseMode:Boolean = !CONFIG::isDebugMode;
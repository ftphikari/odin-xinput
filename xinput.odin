package xinput

import "core:dynlib"

LEFT_THUMB_DEADZONE  :: 7849
RIGHT_THUMB_DEADZONE :: 8689
TRIGGER_THRESHOLD    :: 30
USER_MAX_COUNT       :: 4
XINPUT_FLAG_GAMEPAD  :: 0x00000001

Error :: enum u32 {
	Success = 0,
	NotConnected = 1167,
}

BatteryInformation :: struct {
	type_: BatteryType,
	level: BatteryLevel,
}

Capabilities :: struct {
	type_: u8,
	sub_type: ControllerType,
	flags: CapabilitiesFlags,
	gamepad: GamepadState,
	vibration: VibrationState,
}

State :: struct {
	packet_number: u32,
	gamepad: GamepadState,
}

GamepadState :: struct {
	buttons: u16,
	left_trigger: u8,
	right_trigger: u8,
	lx: i16,
	ly: i16,
	rx: i16,
	ry: i16,
}

VibrationState :: struct {
	left_motor_speed: u16,
	right_motor_speed: u16,
}

KeyStroke :: struct {
	virtual_key: VirtualKeys,
	unicode: u16,
	flags: KeyStrokeFlags,
	user_index: u8,
	hid_code: u8,
}

VirtualKeys :: enum u16 {
	A         = 0x5800,
	B         = 0x5801,
	X         = 0x5802,
	Y         = 0x5803,
	RSHOULDER = 0x5804,
	LSHOULDER = 0x5805,
	LTRIGGER  = 0x5806,
	RTRIGGER  = 0x5807,

	DPAD_UP      = 0x5810,
	DPAD_DOWN    = 0x5811,
	DPAD_LEFT    = 0x5812,
	DPAD_RIGHT   = 0x5813,
	START        = 0x5814,
	BACK         = 0x5815,
	LTHUMB_PRESS = 0x5816,
	RTHUMB_PRESS = 0x5817,

	LTHUMB_UP        = 0x5820,
	LTHUMB_DOWN      = 0x5821,
	LTHUMB_RIGHT     = 0x5822,
	LTHUMB_LEFT      = 0x5823,
	LTHUMB_UPLEFT    = 0x5824,
	LTHUMB_UPRIGHT   = 0x5825,
	LTHUMB_DOWNRIGHT = 0x5826,
	LTHUMB_DOWNLEFT  = 0x5827,

	RTHUMB_UP        = 0x5830,
	RTHUMB_DOWN      = 0x5831,
	RTHUMB_RIGHT     = 0x5832,
	RTHUMB_LEFT      = 0x5833,
	RTHUMB_UPLEFT    = 0x5834,
	RTHUMB_UPRIGHT   = 0x5835,
	RTHUMB_DOWNRIGHT = 0x5836,
	RTHUMB_DOWNLEFT  = 0x5837,
}

KeyStrokeFlags :: enum u16 {
	KeyDown = 0x0001,
	KeyUp   = 0x0002,
	Repeat  = 0x0004,
}

Buttons :: enum u16 {
	DpadUp        = 0x0001,
	DpadDown      = 0x0002,
	DpadLeft      = 0x0004,
	DpadRight     = 0x0008,
	Start         = 0x0010,
	Back          = 0x0020,
	LeftThumb     = 0x0040,
	RightThumb    = 0x0080,
	LeftShoulder  = 0x0100,
	RightShoulder = 0x0200,
	A             = 0x1000,
	B             = 0x2000,
	X             = 0x4000,
	Y             = 0x8000,

	Invalid = 0x0000,
}

BatteryType :: enum u8 {
	Disconnected = 0x00,
	Wired        = 0x01,
	Alkaline     = 0x02,
	Nimh         = 0x03,
	Unknown      = 0xFF,
}

BatteryLevel :: enum u8 {
	Empty  = 0x00,
	Low    = 0x01,
	Medium = 0x02,
	Full   = 0x03,
}

DeviceType :: enum u8 {
	Gamepad = 0x00,
	Headset = 0x01,
}

ControllerType :: enum u8 {
	Unknown     = 0x00,
	Gamepad     = 0x01,
	Wheel       = 0x02,
	ArcadeStick = 0x03,
	FlightStick = 0x04,
	DancePad    = 0x05,
	Guitar      = 0x06,
	GuitarAlt   = 0x07,
	Bass        = 0x0B,
	DrumKit     = 0x08,
	ArcadePad   = 0x13,
}

CapabilitiesFlags :: enum u16 {
	Voice         = 0x0004,
	FFB           = 0x0001,
	Wireless      = 0x0002,
	PMD           = 0x0008,
	NoNavigations = 0x0010,
}

User :: enum u32 {
	Player1 = 0,
	Player2 = 1,
	Player3 = 2,
	Player4 = 3,
}

Enable : proc "stdcall" (enable : b32)
GetBatteryInformation: proc "stdcall" (userIndex : u32, dev_type : DeviceType, out : ^BatteryInformation) -> u32
GetCapabilities: proc "stdcall" (userIndex : u32, type_ : u32, out : ^Capabilities) -> u32
GetKeystroke: proc "stdcall" (userIndex : u32, reserved : u32, out : ^KeyStroke)-> u32
GetState: proc "stdcall" (userIndex : u32, state : ^State) -> u32
SetState: proc "stdcall" (userIndex : u32, state : ^VibrationState) -> u32

get_capabilities :: proc(user: User, only_gamepads := false)  -> (Capabilities, Error) {
	res := Capabilities{}
	g: u32 = only_gamepads ? XINPUT_FLAG_GAMEPAD : 0
	err := GetCapabilities(u32(user), g, &res)
	return res, Error(err)
}

get_state :: proc(user: User) -> (State, Error) {
	res := State{}
	err := GetState(u32(user), &res)
	return res, Error(err)
}

set_state :: proc(user: User, left, right: f32) -> Error {
	res := VibrationState{}
	U16_MAX :: 65535
	res.left_motor_speed = u16(U16_MAX * left)
	res.right_motor_speed = u16(U16_MAX * right)

	err := SetState(u32(user), &res)
	return Error(err)
}

XInputVersion :: enum {
	NotLoaded,
	_1_4,
	_1_3,
	_9_1_0,
	Error,
}

Version: XInputVersion = .NotLoaded

init :: proc(inital_state := true) -> bool {
	lib, ok := dynlib.load_library("xinput1_4.dll") // NOTE(Hoej): Freeing this will make any xinput calls panic at runtime.
	Version = ._1_4
	if !ok {
		lib, ok = dynlib.load_library("xinput1_3.dll")
		Version = ._1_3
	}

	if !ok {
		lib, ok = dynlib.load_library("xinput9_1_0.dll")
		Version = ._9_1_0
	}

	if !ok {
		Version = .Error
		return false
	}

	Enable = cast(type_of(Enable))(dynlib.symbol_address(lib, "XInputEnable"))
	GetBatteryInformation = cast(type_of(GetBatteryInformation))(dynlib.symbol_address(lib, "XInputGetBatteryInformation"))
	GetCapabilities = cast(type_of(GetCapabilities))(dynlib.symbol_address(lib, "XInputGetCapabilities"))
	GetKeystroke = cast(type_of(GetKeystroke))(dynlib.symbol_address(lib, "XInputGetKeystroke"))
	SetState = cast(type_of(SetState))(dynlib.symbol_address(lib, "XInputSetState"))
	GetState = cast(type_of(GetState))(dynlib.symbol_address(lib, "XInputGetState"))

	Enable(b32(inital_state))

	return true
}

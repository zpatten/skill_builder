unit SendKey;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, KeyDefs;

type
  { Error Codes }
  TSendKeyError = (sk_None, sk_FailSetHook, sk_InvalidToken, sk_UnknownError,
                   sk_AlreadyPlaying);
  { First vk code to last vk code }
  TvkKeySet = set of vk_LButton..vk_Scroll;

  { Exceptions }
  ESendKeyError = class(Exception);
  ESKSetHookError = class(ESendKeyError);
  ESKInvalidToken = class(ESendKeyError);
  ESKAlreadyPlaying = class(ESendKeyError);

function SendClicks(X, Y: Longint; Double: Boolean; Button: Byte): TSendKeyError;
function SendKeys(S: String): TSendKeyError;
procedure WaitForHook;
procedure StopPlayback;
procedure StartRecording;
procedure StopRecording;

var
  Playing: Boolean = FALSE;
  Recording: Boolean = FALSE;
  MouseX: Longint;
  MouseY: Longint;
  Clicked: Boolean;

implementation

uses Forms, Main;

type
  { a TList descendent that knows how to dispose of its contents }
  TMessageList = class(TList)
  public
    destructor Destroy; override;
  end;

const
  { valid "sys" keys }
  vkKeySet: TvkKeySet = [Ord('A')..Ord('Z'), vk_Menu, vk_F1..vk_F12];

destructor TMessageList.Destroy;
var
  I: LongInt;
begin
  { deallocate all the message records before discarding the list }
  for I := 0 to Count-1 do
    Dispose(PEventMsg(Items[I]));
  inherited Destroy;
end;

var
  { variables global to the DLL }
  MsgCount: Word = 0;
  MessageBuffer: TEventMsg;
  HookHandle: hHook = 0;
  RecordHookHandle: hHook = 0;
  MessageList: TMessageList = Nil;
  AltPressed, ControlPressed, ShiftPressed: Boolean;

procedure StopPlayback;
{ Unhook the hook, and clean up }
begin
  { if hook is currently active, then unplug it }
  if Playing then
    UnhookWindowsHookEx(HookHandle);
  MessageList.Free;
  Playing := FALSE;
end;


function Play(Code: Integer; wParam, lParam: LongInt): LongInt; stdcall;
{ This is the JournalPlayback callback function.  It is called by Windows }
{ when Windows polls for hardware events.  The code parameter indicates what }
{ to do. }
begin
  case Code of
    hc_Skip: begin
    { hc_Skip means to pull the next message out of out list.  If we }
    { are at the end of the list, it's okay to unhook the JournalPlayback }
    { hook from here. }
      { increment message counter }
      Inc(MsgCount);
      { check to see if all messages have been played }
      if MsgCount >= MessageList.Count then
        StopPlayback
      else
      { copy next message from list into buffer }
        MessageBuffer := TEventMsg(MessageList.Items[MsgCount]^);
      Result := 0;
    end;

    hc_GetNext: begin
    { hc_GetNext means to fill the wParam and lParam with the proper }
    { values so that the message can be played back.  DO NOT unhook }
    { hook from within here.  Return value indicates how much time until }
    { Windows should playback message.  We'll return 0 so that it's }
    { processed right away. }
      { move message in buffer to message queue }
      PEventMsg(lParam)^ := MessageBuffer;
      Result := 0; { process immediately }
    end

  else
    { if Code isn't hc_Skip or hc_GetNext, then call next hook in chain }
    Result := CallNextHookEx(HookHandle, Code, wParam, lParam);
  end;
end;

procedure StartPlayback;
{ Initializes globals and sets the hook }
begin
  { grab first message from list and place in buffer in case we }
  { get a hc_GetNext before and hc_Skip }
  MessageBuffer := TEventMsg(MessageList.Items[0]^);
  { initialize message count and play indicator }
  MsgCount := 0;
  { initialize Alt, Control and  Shift key flags }
  AltPressed := FALSE;
  ControlPressed := FALSE;
  ShiftPressed := FALSE;
  { set the hook! }
  HookHandle := SetWindowsHookEx(wh_JournalPlayback, Play, hInstance, 0);
  if HookHandle = 0 then
    raise ESKSetHookError.Create('Couldn''t set hook')
  else
    Playing := TRUE;
end;

procedure StopRecording;
{ Unhook the hook, and clean up }
begin
  { if hook is currently active, then unplug it }
  if Recording then
    UnhookWindowsHookEx(RecordHookHandle);
//  MessageList.Free;
  Recording := FALSE;
end;

function RecordHook(Code: Integer; wParam, lParam: LongInt): LongInt; stdcall;
var
  ActionMsg: PEventMsg;
begin
  case Code of
    hc_Action: begin
      ActionMsg := PEventMsg(lParam);
      with ActionMsg^ do begin
        case message of
          wm_LButtonDown: begin
          end;
          wm_LButtonUp: begin
            Clicked := TRUE;
          end;
          wm_RButtonDown: begin
          end;
          wm_RButtonUp: begin
            Clicked := TRUE;
          end;
          wm_MButtonDown: begin
          end;
          wm_MButtonUp: begin
            Clicked := TRUE;
          end;
          wm_MouseMove: begin
            MouseX := paramL;
            MouseY := paramH;
          end;
          wm_KeyDown: begin
          end;
          wm_KeyUp: begin
          end;
        end;
      end;
    end;
  end;
  Result := 0;
end;

procedure StartRecording;
begin
  Clicked := FALSE;
  RecordHookHandle := SetWindowsHookEx(wh_JournalRecord, RecordHook, hInstance, 0);
  if RecordHookHandle = 0 then
    raise ESKSetHookError.Create('Couldn''t set record hook')
  else
    Recording := TRUE;
end;

procedure MakeMessage(vKey: Byte; M: Cardinal);
{ procedure builds a TEventMsg record that emulates a keystroke and }
{ adds it to message list }
var
  E: PEventMsg;
begin
  New(E);                              // allocate a message record
  with E^ do begin
    message := M;                      // set message field
    paramL := vKey;                    // vk code in ParamL
    paramH := MapVirtualKey(vKey, 0);  // scan code in ParamH
    time := GetTickCount;              // set time
    hwnd := 0;                         // ignored
  end;
  MessageList.Add(E);
end;

procedure MakeMouseMessage(X, Y: Integer; M: Cardinal);
{ procedure builds a TEventMsg record that emulates a mouse click and }
{ adds it to message list }
var
  E: PEventMsg;
begin
  New(E);
  with E^ do begin
    message := M;
    paramL := X;
    paramH := Y;
    time := GetTickCount;
    hwnd := 0;
  end;
  MessageList.Add(E);
end;

procedure MouseClick(X, Y: LongInt; Double: Boolean; Button: Byte);
begin
  MakeMouseMessage(X, Y, wm_MouseMove);
  case Button of
    0: if Double then // Left Mouse Button
         MakeMouseMessage(X, Y, wm_LButtonDblClk)
       else begin
         MakeMouseMessage(X, Y, wm_LButtonDown);
//         MakeMouseMessage(X, Y, wm_MouseMove);
         MakeMouseMessage(X, Y, wm_LButtonUp);
       end;
    1: if Double then // Right Mouse Button
         MakeMouseMessage(X, Y, wm_RButtonDblClk)
       else begin
         MakeMouseMessage(X, Y, wm_RButtonDown);
//         MakeMouseMessage(X, Y, wm_MouseMove);
         MakeMouseMessage(X, Y, wm_RButtonUp);
       end;
    2: if Double then // Middle Mouse Button
         MakeMouseMessage(X, Y, wm_MButtonDblClk)
       else begin
         MakeMouseMessage(X, Y, wm_MButtonDown);
//         MakeMouseMessage(X, Y, wm_MouseMove);
         MakeMouseMessage(X, Y, wm_MButtonUp);
       end;
    3: MakeMouseMessage(X, Y, wm_LButtonDown);
    4: MakeMouseMessage(X, Y, wm_LButtonUp);
    5: MakeMouseMessage(X, Y, wm_RButtonDown);
    6: MakeMouseMessage(X, Y, wm_RButtonUp);
  end;
end;

procedure KeyDown(vKey: Byte);
{ Generates KeyDown message }
begin
  { don't generate a "sys" key if the control key is pressed (Windows quirk) }
  if AltPressed and (not ControlPressed) and (vKey in vkKeySet) then
    MakeMessage(vKey, wm_SysKeyDown)
  else
    MakeMessage(vKey, wm_KeyDown);
end;

procedure KeyUp(vKey: Byte);
{ Generates KeyUp message }
begin
  { don't generate a "sys" key if the control key is pressed (Windows quirk) }
  if AltPressed and (not ControlPressed) and (vKey in vkKeySet) then
    MakeMessage(vKey, wm_SysKeyUp)
  else
    MakeMessage(vKey, wm_KeyUp);
end;

procedure SimKeyPresses(VKeyCode: Word);
{ This procedure simulates keypresses for the given key, taking into }
{ account the current state of Alt, Control and Shift keys }
begin
  { press Alt key if flag has been set }
  if AltPressed then
    KeyDown(vk_Menu);
  { press Control key if flag has been set }
  if ControlPressed then
    KeyDown(vk_Control);
  { if shift is pressed, or shifted key and control is not pressed... }
  if (((Hi(VKeyCode) and 1) <> 0) and (not ControlPressed)) or ShiftPressed then
    KeyDown(vk_Shift);   { ...press shift }
  KeyDown(Lo(VKeyCode)); { press key down }
  KeyUp(Lo(VKeyCode));   { release key }
  { if shift is pressed, or shifted key and control is not pressed... }
  if (((Hi(VKeyCode) and 1) <> 0) and (not ControlPressed)) or ShiftPressed then
    KeyUp(vk_Shift);     { ...release shift }
  { if shift flag is set, reset flag }
  if ShiftPressed then
    ShiftPressed := FALSE;
  { Release Control key if flag has been set, reset flag }
  if ControlPressed then begin
    KeyUp(vk_Control);
    ControlPressed := FALSE;
  end;
  { Release Alt key if flag has been set, reset flag }
  if AltPressed then begin
    KeyUp(vk_Menu);
    AltPressed := FALSE;
  end;
end;

procedure ProcessClick(X, Y: Integer; Double: Boolean; Button: Word);
begin
  MouseClick(X, Y, Double, Button);
end;

procedure ProcessKey(S: String);
{ This procedure parses each character in the string to create the message list }
var
  KeyCode: Word;
  Key: Byte;
  Index: Integer;
  Token: TKeyString;
begin
  Index := 1;
  repeat
    case S[Index] of
      KeyGroupOpen: begin
      { It's the beginning of a special token! }
        Token := '';
        Inc(Index);
        while S[Index] <> KeyGroupClose do begin
          { add to token until the end token symbol is encountered }
          Token := Token + S[Index];
          Inc(Index);
          { check to make sure the token's not too long }
          if (Length(Token) = 7) and (S[Index] <> KeyGroupClose) then
            raise ESKInvalidToken.Create('No closing brace');
        end;
        { look for token in array, Key parameter will }
        { contain vk code if successful }
        if not FindKeyInArray(Token, Key) then
          raise ESKInvalidToken.Create('Invalid token');
        { simulate keypress sequence }
        SimKeyPresses(MakeWord(Key, 0));
      end;

      AltKey: begin
        { set Alt flag }
        AltPressed := TRUE;
      end;

      ControlKey: begin
        { set Control flag }
        ControlPressed := TRUE;
      end;

      ShiftKey: begin
        { set Shift flag }
        ShiftPressed := TRUE;
      end;

      else begin
      { A normal character was pressed }
        { convert character into a word where the high byte contains }
        { the shift state and the low byte contains the vk code }
        KeyCode := vkKeyScan(S[Index]);
        { simulate keypress sequence }
        SimKeyPresses(KeyCode);
      end;
    end;
    Inc(Index);
  until Index > Length(S);
end;

procedure WaitForHook;
begin
  repeat Application.ProcessMessages until not Playing;
end;

function SendClicks(X, Y: Longint; Double: Boolean; Button: Byte): TSendKeyError;
begin
  Result := sk_None;
  try
    if Playing then raise ESKAlreadyPlaying.Create('');
    MessageList := TMessageList.Create;
    ProcessClick(X, Y, Double, Button);
    StartPlayback;
  except
    { if an exception occurs, return an error code, and clean up }
    on E:ESendKeyError do begin
      MessageList.Free;
      if E is ESKSetHookError then
        Result := sk_FailSetHook
      else if E is ESKInvalidToken then
        Result := sk_InvalidToken
      else if E is ESKAlreadyPlaying then
        Result := sk_AlreadyPlaying;
    end
    else
      { Catch-all exception handler }
      Result := sk_UnknownError;
  end;
end;

function SendKeys(S: String): TSendKeyError;
{ This is the one entry point.  Based on the string passed in the S }
{ parameter, this function creates a list of keyup/keydown messages, }
{ sets a JournalPlayback hook, and replays the keystroke messages. }
begin
  Result := sk_None;              // assume success
  try
    if Playing then raise ESKAlreadyPlaying.Create('');
    MessageList := TMessageList.Create;  // create list of messages
    ProcessKey(S);                       // create messages from string
    StartPlayback;                       // set hook and play back messages
  except
    { if an exception occurs, return an error code, and clean up }
    on E:ESendKeyError do begin
      MessageList.Free;
      if E is ESKSetHookError then
        Result := sk_FailSetHook
      else if E is ESKInvalidToken then
        Result := sk_InvalidToken
      else if E is ESKAlreadyPlaying then
        Result := sk_AlreadyPlaying;
    end
    else
      { Catch-all exception handler }
      Result := sk_UnknownError;
  end;
end;

end.

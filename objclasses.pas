type
  TFifoQueue = class
  private
    FCount: integer;
    FSource: array [0 .. 255] of PChar;
  public
    procedure Push(item: PChar);
    function Pop: PChar;
    property Count: integer read FCount;
  end;

  TMemClass = class
  private
    FAddr, FSize: integer;
  public
    property addr: integer read FAddr write FAddr;
    property Size: integer read FSize write FSize;
  end;

  TSheetList = class
  private
    FCount: integer;
    FSource: array [0 .. 255] of Pointer;
    function GetItem(X: integer): Pointer;
    procedure SetItem(X: integer; const Value: Pointer);
  public
    procedure Add(item: Pointer);
    procedure Move(id, num: integer);
    procedure Insert(id: integer; item: Pointer);
    procedure Delete(id: integer);
    property item[X: integer]: Pointer read GetItem write SetItem; default;
    property Count: integer read FCount;
  end;

  TOSBase = class
  private
    FVram: PByte;
    FXSize, FYSize: integer;
  public
    property Vram: PByte read FVram write FVram;
    property XSize: integer read FXSize write FXSize;
    property YSize: integer read FYSize write FYSize;
  end;

  TFifoClass = class
  protected
    FFifo: TFifoQueue;
    FSize: integer;
    procedure wait_KBC_sendready;
    function GetStatus: integer;
    function fifo8_push(data: Char): Boolean;
    function fifo8_pop: Char;
    procedure inthandler(esp: integer); virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;
    property Status: integer read GetStatus;
  end;

  TKeyFifoClass = class(TFifoClass)
  private
    procedure inthandler(esp: integer); override;
    function GetCount: integer;
  public
    constructor Create;
    property Size: integer read FSize write FSize;
    property Count: integer read GetCount;
  end;

  TMouseClass = class(TFifoClass)
  private
    FVram: PByte;
    FXSize, FYSize: integer;
    FWid, FHei: integer;
    FCursor, FDefault: PChar;
    FMouse: PByte;
    procedure init_mouse_cursor8(cursor: PChar);
    procedure putblock8_8(px, py: integer; bxsize: integer);
    procedure inthandler(esp: integer); override;
  public
    constructor Create;
    property Width: integer read FWid write FWid;
    property Height: integer read FHei write FHei;
  end;

  TMemMan = class
  const
    MEMMAN_FREES = 4090;
  private
    FLostSize, FLosts: integer;
    FMem: TSheetList;
    function GetStrings(X: integer): TMemClass;
    procedure SetStrings(X: integer; const Value: TMemClass);
    function alloc(Size: integer): Pointer;
    procedure Delete(addr, Size: integer);
  public
    constructor Create;
    destructor Destroy; override;
    function total: integer; stdcall;
    function alloc_4k(Size: integer): Pointer; stdcall;
    procedure delete_4k(addr, Size: integer); stdcall;
    property Strings[X: integer]: TMemClass read GetStrings
      write SetStrings; default;
  end;

  TSheet = class
  private
    FBuf: PByte;
    FBxsize, FBysize, FVx, FVy, FCol_inv, FFlags: integer;
  public
    property buf: PByte read FBuf write FBuf;
    property bxsize: integer read FBxsize write FBxsize;
    property bysize: integer read FBysize write FBysize;
    property vx: integer read FVx write FVx;
    property vy: integer read FVy write FVy;
    property col_inv: integer read FCol_inv write FCol_inv;
    property flags: integer read FFlags write FFlags;
  end;

  TFontClass = class
  private
    FBase: TOSBase;
    FFont: Pointer;
    FColor: Byte;
  public
    constructor Create(base: TOSBase);
    procedure putfont8(X, y: integer; c: Char);
    procedure putfonts8_asc(X, y: integer; str: PChar); stdcall;
    property color: Byte read FColor write FColor;
  end;

  TScreenClass = class(TSheet)
  private
    FBase: TOSBase;
  public
    constructor Create(base: TOSBase);
    procedure boxfill8(color: Byte; x0, y0, x1, y1: integer); stdcall;
    procedure init_screen8; stdcall;
  end;

  TSHTCtlClass = class
  private
    function GetHeight: integer;
    function GetSheet(id: integer): TSheet;
    procedure SetSheet(id: integer; const Value: TSheet);
  protected
    FSheets: TSheetList;
    FMem: TMemMan;
    FHeight: integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure slide(id, vx, vy: integer); stdcall;
    procedure updown(id, hei: integer); stdcall;
    property Height: integer read GetHeight;
    property Sheet[X: integer]: TSheet read GetSheet write SetSheet; default;
  end;

  TFrameWork = class(TOSBase)
  private
    FFont: TFontClass;
    FScreen: TScreenClass;
    FKeyboard: TKeyFifoClass;
    FMouse: TMouseClass;
    FWinList: TSHTCtlClass;
    procedure fifo8_init;
  public
    constructor Create;
    destructor Destroy; override;
    procedure refresh; stdcall;
    property Keyboard: TKeyFifoClass read FKeyboard;
    property Mouse: TMouseClass read FMouse;
  end;

  { TFifoQueue }

procedure TFifoQueue.Push(item: PWideChar);
begin
  FSource[FCount] := item;
  inc(FCount);
end;

function TFifoQueue.Pop;
var
  i: integer;
begin
  dec(FCount);
  result := FSource[0];
  for i := 0 to FCount - 1 do
    FSource[i] := FSource[i + 1];
end;

{ TSheetList }

procedure TSheetList.SetItem(X: integer; const Value: Pointer);
begin
  if (0 <= X) and (X < FCount) then
    FSource[X] := Value;
end;

procedure TSheetList.Add(item: Pointer);
begin
  if FCount < 255 then
  begin
    FSource[FCount] := item;
    inc(FCount);
  end;
end;

procedure TSheetList.Move(id: integer; num: integer);
var
  tmp: TMemClass;
  i: integer;
begin
  if (0 <= id) and (id < FCount) and (0 <= num) and (num < FCount) then
  begin
    tmp := FSource[id];
    if id < num then
      for i := id to num - 1 do
        FSource[i] := FSource[i + 1]
    else
      for i := id downto num - 1 do
        FSource[i] := FSource[i - 1];
    FSource[num] := tmp;
  end;
end;

procedure TSheetList.Insert(id: integer; item: Pointer);
begin
  Add(item);
  Move(FCount - 1, id);
end;

procedure TSheetList.Delete(id: integer);
var
  i: integer;
begin
  if (0 <= id) and (id < FCount) then
  begin
    dec(FCount);
    for i := id to FCount - 1 do
      FSource[i] := FSource[i + 1];
  end;
end;

function TSheetList.GetItem(X: integer): Pointer;
begin
  if (0 <= X) and (X < FCount) then
    result := FSource[X]
  else
    result := nil;
end;

{ TFontClass }

constructor TFontClass.Create(base: TOSBase);
begin
  inherited Create;
  FBase := base;
  FColor := Blue;
end;

procedure TFontClass.putfont8(X, y: integer; c: Char);
type
  TFont = array [0 .. 16] of Byte;
var
  i: integer;
  pdata: ^TFont;
  b: Byte;
  p: PByte;
begin
  pdata := FFont;
  for i := 0 to 16 do
  begin
    p := FBase.Vram + (y + i) * FBase.XSize + X;
    b := pdata^[i];
    if b and $80 <> 0 then
      p[0] := FColor;
    if b and $40 <> 0 then
      p[1] := FColor;
    if b and $20 <> 0 then
      p[2] := FColor;
    if b and $10 <> 0 then
      p[3] := FColor;
    if b and $08 <> 0 then
      p[4] := FColor;
    if b and $04 <> 0 then
      p[5] := FColor;
    if b and $02 <> 0 then
      p[6] := FColor;
    if b and $01 <> 0 then
      p[7] := FColor;
  end;
end;

procedure TFontClass.putfonts8_asc(X, y: integer; str: PChar); stdcall;
var
  i: integer;
begin
  i := 0;
  while str[i] <> '' do
  begin
    putfont8(X, y, str[i]);
    inc(X, 8);
    inc(i);
  end;
end;

{ TScreenClass }

constructor TScreenClass.Create(base: TOSBase);
begin
  inherited Create;
  FBase := base;
end;

procedure TScreenClass.boxfill8(color: Byte; x0, y0, x1, y1: integer); stdcall;
var
  X, y: integer;
begin
  for y := y0 to y1 do
    for X := x0 to x1 do
      FBase.Vram[y * FBase.XSize + X] := Byte(color);
end;

procedure TScreenClass.init_screen8; stdcall;
begin
  with FBase do
  begin
    boxfill8(col8_008484, 0, 0, XSize - 1, YSize - 29);
    boxfill8(col8_c6c6c6, 0, YSize - 28, XSize - 1, YSize - 28);
    boxfill8(col8_ffffff, 0, YSize - 27, XSize - 1, YSize - 27);
    boxfill8(col8_c6c6c6, 0, YSize - 26, XSize - 1, YSize - 1);

    boxfill8(col8_ffffff, 3, YSize - 24, 59, YSize - 24);
    boxfill8(col8_ffffff, 2, YSize - 24, 2, YSize - 4);
    boxfill8(col8_848484, 3, YSize - 4, 59, YSize - 4);
    boxfill8(col8_848484, 59, YSize - 23, 59, YSize - 5);
    boxfill8(col8_000000, 2, YSize - 3, 59, YSize - 3);
    boxfill8(col8_000000, 60, YSize - 24, 60, YSize - 3);

    boxfill8(col8_848484, XSize - 47, YSize - 24, XSize - 4, YSize - 24);
    boxfill8(col8_848484, XSize - 47, YSize - 23, XSize - 47, YSize - 4);
    boxfill8(col8_ffffff, XSize - 47, YSize - 3, XSize - 4, YSize - 3);
    boxfill8(col8_ffffff, XSize - 3, YSize - 24, XSize - 3, YSize - 3);
  end;
end;

{ TFifoClass }

constructor TFifoClass.Create;
begin
  inherited;
  FFifo := TFifoQueue.Create;
end;

destructor TFifoClass.Destroy;
begin
  FFifo.Free;
  inherited;
end;

procedure TFifoClass.wait_KBC_sendready;
begin
  repeat
    ;
  until io_in8(PORT_KEYSTA) and KEYSTA_SEND_NOTREADY = 0;
end;

function TFifoClass.fifo8_push(data: Char): Boolean;
var
  p: PChar;
begin
  if FFifo.Count < FSize then
  begin
    New(p);
    p^ := data;
    FFifo.Push(p);
    result := true;
  end
  else
    result := false;
end;

function TFifoClass.fifo8_pop: Char;
var
  p: PChar;
begin
  if FFifo.Count > 0 then
  begin
    p := FFifo.Pop;
    result := p^;
    Dispose(p);
  end
  else
    result := #0;
end;

function TFifoClass.GetStatus: integer;
begin
  result := FSize - FFifo.Count;
end;

{ KeyFifoClass }

constructor TKeyFifoClass.Create;
begin
  inherited;
  FSize := 32;
  wait_KBC_sendready;
  io_out8(PORT_KEYCMD, KEYCMD_WRITE_MODE);
  wait_KBC_sendready;
  io_out8(PORT_KEYDAT, KBC_MODE);
end;

procedure TKeyFifoClass.inthandler(esp: integer);
var
  data: Char;
begin
  io_out8(PIC0_OCW2, $61);
  data := Char(io_in8(PORT_KEYDAT));
  fifo8_push(data);
end;

function TKeyFifoClass.GetCount: integer;
begin
  result := FFifo.Count;
end;

{ TMouseClass }

constructor TMouseClass.Create;
var
  hdr: ^TMultiboot_hdr;
begin
  inherited;
  hdr := Pointer(0);
  FVram := hdr^.screen_addr;
  FXSize := hdr^.Width;
  FYSize := hdr^.Height;
  FWid := 16;
  FHei := 16;
  init_mouse_cursor8(nil);
  wait_KBC_sendready;
  io_out8(PORT_KEYCMD, KEYCMD_SENDTO_MOUSE);
  wait_KBC_sendready;
  io_out8(PORT_KEYDAT, MOUSECMD_ENABLE);
end;

procedure TMouseClass.init_mouse_cursor8(cursor: PChar);
var
  X, y: integer;
  procedure build(data: array of string);
  var
    i, j, k: integer;
  begin
    k := 0;
    for j := 1 to 16 do
      for i := 1 to 16 do
      begin
        FDefault[k] := data[j, i];
        inc(k);
      end;
  end;

begin
  if cursor = nil then
  begin
    build([ //
      '**************..', //
      '*00000000000*...', //
      '*0000000000*....', //
      '*000000000*.....', //
      '*00000000*......', //
      '*0000000*.......', //
      '*0000000*.......', //
      '*00000000*......', //
      '*0000**000*.....', //
      '*000*..*000*....', //
      '*00*....*000*...', //
      '*0*......*000*..', //
      '**........*000*.', //
      '*..........*000*', //
      '............*00*', //
      '.............***']);
    FCursor := FDefault;
  end
  else
    FCursor := cursor;
  X := 0;
  y := 0;
  repeat
    case FCursor[X] of
      '*':
        FMouse[FWid * y + X] := col8_000000;
      '0':
        FMouse[FWid * y + X] := col8_ffffff;
      '.':
        FMouse[FWid * y + X] := Yellow;
    end;
    if X >= FWid then
    begin
      X := 0;
      inc(y);
    end;
  until y >= FHei;
end;

procedure TMouseClass.putblock8_8(px, py: integer; bxsize: integer);
var
  X, y: integer;
begin
  for y := 0 to FYSize - 1 do
    for X := 0 to FXSize - 1 do
      FVram[(py + y) * FXSize + px + X] := FMouse[y * bxsize + X];
end;

procedure TMouseClass.inthandler(esp: integer);
var
  data: Byte;
begin
  io_out8(PIC1_OCW2, $64);
  io_out8(PIC0_OCW2, $62);
  data := io_in8(PORT_KEYDAT);
  fifo8_push(Char(data));
end;

{ TFrameWork }

constructor TFrameWork.Create;
begin
  inherited;
  FFont := TFontClass.Create(Self);
  FScreen := TScreenClass.Create(Self);
  FKeyboard := TKeyFifoClass.Create;
  FMouse := TMouseClass.Create;
  FScreen.init_screen8;
  FFont.putfonts8_asc(0, 0, 'masasi fuke');
  FMouse.init_mouse_cursor8(nil);
  fifo8_init;
end;

destructor TFrameWork.Destroy;
begin
  FFont.Free;
  FScreen.Free;
  FKeyboard.Free;
  FMouse.Free;
  inherited;
end;

procedure TFrameWork.fifo8_init;
var
  c: Char;
begin
  io_cli;
  FFont.color := col8_008484;
  if FKeyboard.Status + FMouse.Status = 0 then
    io_stihlt
  else if FKeyboard.Status <> 0 then
  begin
    c := FKeyboard.fifo8_pop;
    io_sti;
    FScreen.boxfill8(col8_008484, 32, 16, 47, 31);
    FFont.putfont8(32, 16, c);
  end
  else if FMouse.Status <> 0 then
  begin
    c := FMouse.fifo8_pop;
    io_sti;
    FScreen.boxfill8(col8_008484, 32, 16, 47, 31);
    FFont.putfont8(32, 16, c);
  end;
end;

procedure TFrameWork.refresh; stdcall;
var
  i: integer;
  sht: TSheet;
  c: Byte;
  X, y, bx, by: integer;
begin
  for i := FWinList.Height - 1 downto 0 do
  begin
    sht := FWinList[i];
    for y := 0 to sht.bysize do
    begin
      by := sht.vy + y;
      for X := 0 to sht.bxsize do
      begin
        bx := sht.vx + X;
        c := sht.buf[y * sht.bxsize + X];
        if c <> sht.col_inv then
          FVram[by * sht.bxsize + bx] := c;
      end;
    end;
  end;
end;

{ TMemMan }

function TMemMan.GetStrings(X: integer): TMemClass;
begin
  if (0 <= X) and (X <= MEMMAN_FREES) then
    result := FMem[X]
  else
    result := nil;
end;

procedure TMemMan.SetStrings(X: integer; const Value: TMemClass);
begin
  if (0 <= X) and (X <= MEMMAN_FREES) then
    FMem[X] := Value;
end;

constructor TMemMan.Create;
begin
  inherited;
  FLostSize := 0;
  FLosts := 0;
end;

destructor TMemMan.Destroy;
begin
  FMem.Free;
  inherited;
end;

function TMemMan.alloc(Size: integer): Pointer;
var
  i: integer;
  obj: TMemClass;
begin
  result := Pointer(0);
  for i := 0 to FMem.Count - 1 do
    if TMemClass(FMem[i]).Size >= Size then
    begin
      obj := FMem[i];
      result := Pointer(obj.addr);
      obj.addr := obj.addr + Size;
      obj.Size := obj.Size - Size;
      if obj.Size = 0 then
        FMem.Delete(i);
    end;
end;

function TMemMan.total: integer; stdcall;
var
  i: integer;
begin
  result := 0;
  for i := 0 to FMem.Count - 1 do
    inc(result, TMemClass(FMem[i]).Size);
end;

procedure TMemMan.Delete(addr, Size: integer);
var
  i: integer;
  obj, tmp: TMemClass;
begin
  for i := 0 to FMem.Count - 1 do
    if TMemClass(FMem[i]).addr > addr then
    begin
      obj := FMem[i - 1];
      tmp := FMem[i];
      if obj.addr + obj.Size = addr then
      begin
        obj.Size := obj.Size + Size;
        if addr + Size < tmp.addr then
        begin
          obj.Size := obj.Size + tmp.Size;
          tmp.Free;
          FMem.Delete(i);
        end;
      end
      else if addr + Size = tmp.addr then
      begin
        tmp.addr := addr;
        tmp.Size := tmp.Size + Size;
      end
      else
      begin
        obj.Create;
        obj.addr := addr;
        obj.Size := Size;
        FMem.Insert(i, obj);
      end;
      break;
    end;
end;

function TMemMan.alloc_4k(Size: integer): Pointer;
begin
  Size := (Size + $FFF) and $FFFFF000;
  result := alloc(Size);
end;

procedure TMemMan.delete_4k(addr: integer; Size: integer);
begin
  Size := (Size + $FFF) and $FFFFF000;
  Delete(addr, Size);
end;

{ TSHTCtlClass }

constructor TSHTCtlClass.Create;
var
  i: integer;
  sht: TSheet;
begin
  inherited;
  FMem := TMemMan.Create;
  for i := 0 to MAX_SHEETS do
  begin
    sht := FMem.alloc_4k(SizeOf(TSheet));
    FSheets.Add(sht);
    sht.col_inv := 0;
    sht.flags := 0;
  end;
  for i := 0 to MAX_SHEETS do
  begin
    sht := FSheets[i];
    sht.buf := FMem.alloc(100);
  end;
end;

destructor TSHTCtlClass.Destroy;
var
  i: integer;
  sht: TSheet;
begin
  for i := 0 to FSheets.Count - 1 do
  begin
    sht := FSheets[i];
    FMem.Delete(integer(sht.buf), 100);
    FMem.Delete(integer(sht), SizeOf(TSheet));
  end;
  FMem.Free;
  inherited;
end;

procedure TSHTCtlClass.slide(id: integer; vx: integer; vy: integer); stdcall;
var
  sht: TSheet;
begin
  sht := FSheets[id];
  sht.vx := vx;
  sht.vy := vy;
  FSheets[id] := sht;
end;

function TSHTCtlClass.GetHeight;
var
  i: integer;
  sht: TSheet;
begin
  result := 0;
  for i := 0 to FSheets.Count - 1 do
  begin
    sht := FSheets[i];
    if sht.flags = 0 then
    begin
      result := i;
      break;
    end;
  end;
end;

procedure TSHTCtlClass.updown(id: integer; hei: integer); stdcall;
begin
  if hei < -1 then
    hei := 0;
  if Height > GetHeight then
    hei := GetHeight;
  FSheets.Move(id, hei);
end;

function TSHTCtlClass.GetSheet(id: integer): TSheet;
begin
  if (0 <= id) and (id < GetHeight) then
    result := FSheets[id]
  else
    result := nil;
end;

procedure TSHTCtlClass.SetSheet(id: integer; const Value: TSheet);
begin
  if (0 <= id) and (id < GetHeight) then
    FSheets[id] := Value;
end;

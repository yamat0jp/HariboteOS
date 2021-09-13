type
  TFontClass = class
  private
    FVram: PByte;
    FFont: Pointer;
    FXSize, FYSize: integer;
    FColor: Byte;
    procedure putfont8(x, y: integer; c: Char);
  public
    constructor Create;
    procedure putfonts8_asc(x, y: integer; str: PChar); stdcall;
    property color: Byte read FColor write FColor;
  end;

  TScreenClass = class
  private
    FVram: PByte;
    FXSize, FYSize: integer;
  public
    constructor Create;
    procedure boxfill8(color: Byte; x0, y0, x1, y1: integer); stdcall;
    procedure init_screen8; stdcall;
  end;

  TFifoClass = class
  protected
    FFifo: TQueue;
    FSize: integer;
    procedure wait_KBC_sendready;
    function GetStatus: integer;
    function fifo8_push(data: Char): Boolean;
    function fifo8_pop: Char;
  public
    constructor Create;
    destructor Destroy; override;
    property Status: integer read GetStatus;
  end;

  TKeyFifoClass = class(TFifoClass)
  private
    procedure inthandler21(esp: integer);
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
    procedure putblock8_8(px, py: integer; buf: PByte; bxsize: integer);
    procedure inthandler2c(esp: integer); stdcall;
  public
    constructor Create;
    property Width: integer read FWid write FWid;
    property Height: integer read FHei write FHei;
  end;

  TMemMan = class
  const
    MEMMAN_FREES = 4090;

  type
    TMemInfo = record
      addr, Size: integer;
    end;
  private
    FLostSize, FLosts: integer;
    FMem: TList<TMemInfo>;
    function GetStrings(x: integer): TMemInfo;
    procedure SetStrings(x: integer; const Value: TMemInfo);
    function alloc(Size: integer): Pointer;
    procedure delete(addr, Size: integer);
  public
    constructor Create;
    destructor Destroy; override;
    function total: integer; stdcall;
    function alloc_4k(Size: integer): Pointer; stdcall;
    procedure delete_4k(addr, Size: integer); stdcall;
    property Strings[x: integer]: TMemInfo read GetStrings
      write SetStrings; default;
  end;

  TFrameWork = class
  private
    FFont: TFontClass;
    FScreen: TScreenClass;
    FKeyboard: TKeyFifoClass;
    FMouse: TMouseClass;
    procedure fifo8_init;
  public
    constructor Create;
    destructor Destroy; override;
    property Font: TFontClass read FFont;
    property Screen: TScreenClass read FScreen;
    property Keyboard: TKeyFifoClass read FKeyboard;
    property Mouse: TMouseClass read FMouse;
  end;

  TSheet = record
    bxsize, bysize: integer;
    vx, vy: integer;
    col_inv: integer;
    flags: integer;
  end;

  TSHTCtlClass = class
  const
    MAX_SHEETS = 255;
    SHEET_USE = 1;
  private
    function GetHeight: integer;
  protected
    FSheets: TList;
    FMem: TMemMan;
    FVram: PByte;
    FXSize, FYSize: integer;
    FHeight: integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure refresh; stdcall;
    procedure slide(id, vx, vy: integer); stdcall;
    procedure updown(id, hei: integer); stdcall;
    property xsize: integer read FXSize write FXSize;
    property ysize: integer read FYSize write FYSize;
    property Height: integer read GetHeight;
  end;

  { TFontClass }

constructor TFontClass.Create;
var
  bootinfo: ^TMultiboot_hdr;
begin
  inherited;
  bootinfo := Pointer(0);
  FVram := PByte(bootinfo^.screen_addr);
  FFont := bootinfo^.font_addr;
  FXSize := bootinfo^.Width;
  FYSize := bootinfo^.Height;
  FColor := Blue;
end;

procedure TFontClass.putfont8(x, y: integer; c: Char);
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
    p := FVram + (y + i) * FXSize + x;
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

procedure TFontClass.putfonts8_asc(x, y: integer; str: PChar); stdcall;
var
  i: integer;
begin
  i := 0;
  while str[i] <> '' do
  begin
    putfont8(x, y, str[i]);
    inc(x, 8);
    inc(i);
  end;
end;

{ TScreenClass }

constructor TScreenClass.Create;
var
  hdr: ^TMultiboot_hdr;
begin
  inherited;
  hdr := Pointer(0);
  FVram := hdr^.screen_addr;
  FXSize := hdr^.Width;
  FYSize := hdr^.Height;
end;

procedure TScreenClass.boxfill8(color: Byte; x0, y0, x1, y1: integer); stdcall;
var
  x, y: integer;
begin
  for y := y0 to y1 do
    for x := x0 to x1 do
      FVram[y * FXSize + x] := Byte(color);
end;

procedure TScreenClass.init_screen8; stdcall;
begin
  boxfill8(col8_008484, 0, 0, FXSize - 1, FYSize - 29);
  boxfill8(col8_c6c6c6, 0, FYSize - 28, FXSize - 1, FYSize - 28);
  boxfill8(col8_ffffff, 0, FYSize - 27, FXSize - 1, FYSize - 27);
  boxfill8(col8_c6c6c6, 0, FYSize - 26, FXSize - 1, FYSize - 1);

  boxfill8(col8_ffffff, 3, FYSize - 24, 59, FYSize - 24);
  boxfill8(col8_ffffff, 2, FYSize - 24, 2, FYSize - 4);
  boxfill8(col8_848484, 3, FYSize - 4, 59, FYSize - 4);
  boxfill8(col8_848484, 59, FYSize - 23, 59, FYSize - 5);
  boxfill8(col8_000000, 2, FYSize - 3, 59, FYSize - 3);
  boxfill8(col8_000000, 60, FYSize - 24, 60, FYSize - 3);

  boxfill8(col8_848484, FXSize - 47, FYSize - 24, FXSize - 4, FYSize - 24);
  boxfill8(col8_848484, FXSize - 47, FYSize - 23, FXSize - 47, FYSize - 4);
  boxfill8(col8_ffffff, FXSize - 47, FYSize - 3, FXSize - 4, FYSize - 3);
  boxfill8(col8_ffffff, FXSize - 3, FYSize - 24, FXSize - 3, FYSize - 3);
end;

{ TFifoClass }

constructor TFifoClass.Create;
begin
  inherited;
  FFifo := TQueue.Create;
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

procedure TKeyFifoClass.inthandler21(esp: integer);
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
  x, y: integer;
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
  x := 0;
  y := 0;
  repeat
    case FCursor[x] of
      '*':
        FMouse[FWid * y + x] := col8_000000;
      '0':
        FMouse[FWid * y + x] := col8_ffffff;
      '.':
        FMouse[FWid * y + x] := Yellow;
    end;
    if x >= FWid then
    begin
      x := 0;
      inc(y);
    end;
  until y >= FHei;
end;

procedure TMouseClass.putblock8_8(px, py: integer; buf: PByte; bxsize: integer);
var
  x, y: integer;
begin
  for y := 0 to FYSize - 1 do
    for x := 0 to FXSize - 1 do
      FVram[(py + y) * FXSize + px + x] := buf[y * bxsize + x];
end;

procedure TMouseClass.inthandler2c(esp: integer); stdcall;
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
  FFont := TFontClass.Create;
  FScreen := TScreenClass.Create;
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

{ TMemMan }

function TMemMan.GetStrings(x: integer): TMemInfo;
begin
  if (0 <= x) and (x <= MEMMAN_FREES) then
    result := FMem[x];
end;

procedure TMemMan.SetStrings(x: integer; const Value: TMemInfo);
begin
  if (0 <= x) and (x <= MEMMAN_FREES) then
    FMem[x] := Value;
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
  rec: TMemInfo;
begin
  result := Pointer(0);
  for i := 0 to FMem.Count - 1 do
    if FMem[i].Size >= Size then
    begin
      rec := FMem[i];
      result := Pointer(rec.addr);
      inc(rec.addr, Size);
      dec(rec.Size, Size);
      if FMem[i].Size = 0 then
        FMem.delete(i);
    end;
end;

function TMemMan.total: integer; stdcall;
var
  i: integer;
begin
  result := 0;
  for i := 0 to FMem.Count - 1 do
    inc(result, FMem[i].Size);
end;

procedure TMemMan.delete(addr, Size: integer);
var
  i: integer;
  rec: TMemInfo;
begin
  for i := 0 to FMem.Count - 1 do
    if FMem[i].addr > addr then
    begin
      if FMem[i - 1].addr + FMem[i - 1].Size = addr then
      begin
        rec := FMem[i - 1];
        inc(rec.Size, Size);
        FMem[i - 1] := rec;
        if addr + Size < FMem[i].addr then
        begin
          rec := FMem[i - 1];
          inc(rec.Size, FMem[i].Size);
          FMem[i - 1] := rec;
          FMem.delete(i);
        end;
      end
      else if addr + Size = FMem[i].addr then
      begin
        rec.addr := addr;
        rec.Size := FMem[i].Size + Size;
        FMem[i] := rec;
      end
      else
      begin
        rec.addr := addr;
        rec.Size := Size;
        FMem.Insert(i, rec);
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
  delete(addr, Size);
end;

{ TSHTCtlClass }

constructor TSHTCtlClass.Create;
var
  i: integer;
  sht: ^TSheet;
begin
  inherited;
  FMem := TMemMan.Create;
  FXSize := 100;
  FYSize := 100;
  FSheets.Capacity := MAX_SHEETS;
  for i := 0 to MAX_SHEETS do
  begin
    sht := FMem.alloc_4k(SizeOf(TSheet));
    FSheets.Add(sht);
    sht^.bxsize := FXSize;
    sht^.bysize := FYSize;
    sht^.flags := 0;
  end;
end;

destructor TSHTCtlClass.Destroy;
var
  i: integer;
begin
  for i := 0 to FSheets.Count - 1 do
    FMem.delete(integer(FSheets[i]), SizeOf(TSheet));
  FMem.Free;
  inherited;
end;

procedure TSHTCtlClass.refresh; stdcall;
var
  i: integer;
  sht: ^TSheet;
  c: Byte;
  x, y, xx, yy: integer;
begin
  for i := Height - 1 downto 0 do
  begin
    sht := FSheets[i];
    for y := 0 to sht.bysize do
    begin
      yy := sht.vy + y;
      for x := 0 to sht.bxsize do
      begin
        xx := sht.vx + x;
        c := buf[y * sht.bxsize + x];
        if c <> sht.col_inv then
          FVram[yy * sht.bxsize + xx] := c;
      end;
    end;
  end;
end;

procedure TSHTCtlClass.slide(id: integer; vx: integer; vy: integer); stdcall;
var
  sht: ^TSheet;
begin
  sht := FSheets[id];
  sht^.vx := vx;
  sht^.vy := vy;
  FSheets[id] := sht;
  if Height > 0 then
    refresh;
end;

function TSHTCtlClass.GetHeight;
var
  i: integer;
  sht: ^TSheet;
begin
  result := 0;
  for i := 0 to FSheets.Count - 1 do
  begin
    sht := FSheets[i];
    if sht^.flags = 0 then
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
  refresh;
end;

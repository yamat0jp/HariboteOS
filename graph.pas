unit graph;

interface

uses io_procs;

procedure set_palette(start, stop: integer; rgb: PByte); stdcall;
procedure init_palette; stdcall;

implementation

procedure set_palette(start, stop: integer; rgb: PByte); stdcall;
var
  i, eflags: integer;
begin
  eflags := io_load_eflags;
  io_cli;
  io_out8($03C8, start);
  for i := start to stop do
  begin
    io_out8($03C9, rgb[0] shr 2);
    io_out8($03C9, rgb[1] shr 2);
    io_out8($03C9, rgb[2] shr 2);
    inc(rgb, 3);
  end;
  io_store_eflags(eflags);
end;

procedure init_palette; stdcall;
var
  table_rgb: array [0 .. 15 * 3] of Byte;
  procedure setting(data: array of Byte);
  var
    i: integer;
  begin
    for i := 0 to High(data) do
      table_rgb[i] := data[i];
  end;

begin
  setting([$00, $00, $00, //
    $FF, $00, $00, //
    $00, $FF, $00, //
    $FF, $FF, $00, //
    $00, $00, $FF, //
    $FF, $00, $FF, //
    $00, $FF, $FF, //
    $FF, $FF, $FF, //
    $C6, $C6, $C6, //
    $84, $00, $00, //
    $00, $84, $00, //
    $00, $00, $84, //
    $84, $00, $84, //
    $84, $84, $00, //
    $00, $84, $84, //
    $84, $84, $84]);
  set_palette(1, 16, @table_rgb);
end;

end.


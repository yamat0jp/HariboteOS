procedure set_segmdesc(var sd: TSegment; limit, base, ar: cardinal); stdcall;
begin
  if limit > $FFFFF then
  begin
    ar := ar or $8000;
    limit := limit div $1000;
  end;
  sd.limit_low := limit and $FFFF;
  sd.base_low := base and $FFFF;
  sd.base_mid := (base shr 16) and $FF;
  sd.base_hight := (base shr 24) and $FF;
end;

procedure set_gatedesc(var gd: TGate; offset, selector, ar: cardinal); stdcall;
begin
  gd.offset_low := offset and $FFFF;
  gd.selector := selector;
  gd.dw_count := (ar shr 8) and $FF;
  gd.access_right := ar and $FF;
  gd.offset_hight := (offset shr 16) and $FFFF;
end;

procedure init_gdtidt; stdcall;
var
  gdt: ^TSegment;
  idt: ^TGate;
  i, p: integer;
begin
  gdt := Pointer(ADR_GDT);
  idt := Pointer(ADR_IDT);
  for i := 0 to LIMIT_GDT do
  begin
    inc(PByte(gdt));
    set_segmdesc(gdt^, 0, 0, 0);
  end;
  inc(PByte(gdt));
  set_segmdesc(gdt^, $FFFFFFFF, $00000000, AR_DATA32_RW);
  inc(PByte(gdt));
  set_segmdesc(gdt^, LIMIT_BOTPAK, ADR_BOTPAK, AR_CODE32_ER);
  load_gdtr(LIMIT_GDT, ADR_GDT);
  p:=integer(idt);
  for i := 0 to LIMIT_IDT do
  begin
    inc(PByte(idt), i);
    set_gatedesc(idt^, 0, 0, 0);
  end;
  load_idtr(LIMIT_IDT, ADR_IDT);
  idt := Pointer(p + $21);
  set_gatedesc(idt^, cardinal(@asm_inthandler21), 2 * 8, AR_INTGATE32);
  idt := Pointer(p + $27);
  set_gatedesc(idt^, cardinal(@asm_inthandler27), 2 * 8, AR_INTGATE32);
  idt := Pointer(p + $2C);
  set_gatedesc(idt^, cardinal(@asm_inthandler2c), 2 * 8, AR_INTGATE32);
end;

procedure write_mem8(addr, data: integer); stdcall;
asm
  mov ecx,[esp+4]
  mov al,[esp+8]
  mov [ecx],al
  ret
end;

procedure init_pic; stdcall;
begin
  io_out8(pic0_imr, $FF);
  io_out8(pic1_imr, $FF);

  io_out8(pic0_icw1, $11);
  io_out8(pic0_icw2, $20);
  io_out8(pic0_icw3, 1 shl 2);
  io_out8(pic0_icw4, $01);

  io_out8(pic1_icw1, $11);
  io_out8(pic1_icw2, $28);
  io_out8(pic1_icw3, 2);
  io_out8(pic1_icw4, $01);

  io_out8(pic0_imr, $FB);
  io_out8(pic1_imr, $FF);
end;


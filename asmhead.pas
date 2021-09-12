const
  Blue = 1;
  Red = 4;
  Yellow = 14;
  White = 15;

  col8_000000 = 0;
  col8_ff0000 = 1;
  col8_00ff00 = 2;
  col8_ffff00 = 3;
  col8_0000ff = 4;
  col8_ff00ff = 5;
  col8_00ffff = 6;
  col8_ffffff = 7;
  col8_c6c6c6 = 8;
  col8_840000 = 9;
  col8_008400 = 10;
  col8_848400 = 11;
  col8_000084 = 12;
  col8_840084 = 13;
  col8_008484 = 14;
  col8_848484 = 15;

  ADR_BOOTINFO = $00000FF0;
  ADR_DISKIMG = $00100000;

  ADR_IDT = $0026F800;
  LIMIT_IDT = $000007FF;
  ADR_GDT = $00270000;
  LIMIT_GDT = $0000FFFF;
  ADR_BOTPAK = $00280000;
  LIMIT_BOTPAK = $0007FFFF;
  AR_DATA32_RW = $4092;
  AR_CODE32_ER = $409A;
  AR_INTGATE32 = $008E;

  PORT_KEYDAT = $0060;
//  FLAGS_OVERRUN = $0001;

  PIC0_ICW1 = $0020;
  PIC0_OCW2 = $0020;
  PIC0_IMR = $0021;
  PIC0_ICW2 = $0021;
  PIC0_ICW3 = $0021;
  PIC0_ICW4 = $0021;
  PIC1_ICW1 = $00A0;
  PIC1_OCW2 = $00A0;
  PIC1_IMR = $00A1;
  PIC1_ICW2 = $00A1;
  PIC1_ICW3 = $00A1;
  PIC1_ICW4 = $00A1;

type
  TBootInfo = packed record
    cyls: Int16;
    leds: Int8;
    vmode, scrnx, scrny: Int16;
    vram, hankaku: Pointer;
  end;

  TSegment = packed record
    limit_low, base_low: Int16;
    base_mid, access_right: Int16;
    limit_hight, base_hight: Int16;
  end;

  TGate = packed record
    offset_low, selector: Int16;
    dw_count, access_right: Int16;
    offset_hight: Int16;
  end;

  TMultiboot_hdr = packed record
    magic, flags, checksum: cardinal;
    header_addr, load_addr, load_end_addr, bss_end_addr, entry_addr: cardinal;
    mode_type: cardinal;
    width, height, depth: cardinal;
    screen_addr, font_addr: Pointer;
  end;


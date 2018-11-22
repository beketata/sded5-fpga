/******************************************************************************

  Прошивка XILINX XC2S50E для программатора XELTEK SuperPro 6100.
  
******************************************************************************/

module xeltek
(
	// Сигналы, идущие к процессору

	input      [6:1]    A_i,
	inout     [15:0]    D_io,
	input               NRD_i_n,
	input               NWE_i_n,
	input               NCS2_RD_i_n,

	// Сигналы идущие к сокете

	inout     [15:0]    SOCKET_DATA_io,
	inout     [16:0]    SOCKET_ADDR_o,

	inout               SOCKET_RSTIN_o_n,
 	inout               SOCKET_CE_o_n,
	inout               SOCKET_OE_o_n,
	inout               SOCKET_WE_o_n,

	inout               SOCKET_ID0_o_n,
	inout               SOCKET_LOCK_o_n,

	input               SOCKET_BUSY_i_n
);

// Внутренние регистры

reg                   enable_reg = 1'b 1;
reg         [15:0]    addr_reg = 0;
reg         [15:0]    data_reg = 0;
reg          [3:0]    control_reg = 4'b 0111;

// Подача статических уровней на некоторые ножки

assign  SOCKET_ID0_o_n  = ( !enable_reg ) ? 0     : 1'b Z;
assign  SOCKET_LOCK_o_n = ( !enable_reg ) ? 1'b 1 : 1'b Z;

// Подключение входов/выходов к сокете

assign  SOCKET_ADDR_o[16]   = ( !enable_reg ) ? 0        : 1'b Z;
assign  SOCKET_ADDR_o[15:0] = ( !enable_reg ) ? addr_reg : 16'h ZZZZ;

assign  SOCKET_RSTIN_o_n = ( !enable_reg ) ? control_reg[3] : 1'b Z;
assign  SOCKET_CE_o_n    = ( !enable_reg ) ? control_reg[2] : 1'b Z;
assign  SOCKET_OE_o_n    = ( !enable_reg ) ? control_reg[1] : 1'b Z;
assign  SOCKET_WE_o_n    = ( !enable_reg ) ? control_reg[0] : 1'b Z;

assign  SOCKET_DATA_io = ( !enable_reg && control_reg[1] ) ? data_reg : 16'h ZZZZ;

// Чтение из внутренних регистров и с ножек сокеты

assign  D_io = ( !NCS2_RD_i_n && A_i == 6'b 001000 && !NRD_i_n ) ? addr_reg                       :
               ( !NCS2_RD_i_n && A_i == 6'b 001001 && !NRD_i_n ) ? SOCKET_DATA_io                 :
               ( !NCS2_RD_i_n && A_i == 6'b 001010 && !NRD_i_n ) ? { 15'h 0000, SOCKET_BUSY_i_n } :
                                                                   16'h ZZZZ;

//=============================================================================
// Синхронная схемотехника

// Запись во внутренние регистры

always @( posedge NWE_i_n )
begin

  if( !enable_reg )
  begin
    // 0x30000010 - регистр адреса
    if( A_i == 6'b 001000 )
      addr_reg <= D_io;

    // 0x30000012 - регистр данных
    if( A_i == 6'b 001001 )
      data_reg <= D_io;

    // 0x30000014 - регистр управления/статуса
    if( A_i == 6'b 001010 )
      control_reg <= D_io[7:0];

    // 0x30000016 - регистр разрешения работы
    if( A_i == 6'b 001011 )
      enable_reg <= D_io[7];
  end
  else
  begin
    // 0x30000016 - регистр разрешения работы
    if( A_i == 6'b 001011 )
      enable_reg <= D_io[7];
  end

end

endmodule

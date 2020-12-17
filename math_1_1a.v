
module math_1_1a(output wire[7:0]row,
col_r,
col_g,
input clk_1kHz,
input rst,//这个值没有用到
input sw1,//拨码开关的位置是电路板上的sw2
input a1,a2,a3,a4,a5,//a1 a2 对应BTN1和BTN2控制温度的加减，a3 a4是BTN3 BTN4控制倒计时的大小，a5对应BTN0控制倒计时开始
output wire [7:0] seg_led1,cat//数码管显示1/个位
);//十位
		wire clk_1Hz,clk_2Hz,clk_4Hz,cpc;
		wire [2:0]jishu;//控制单个状态的计数器
		wire [1:0]kind;//这是一个控制四个状态转换的计数器
		wire [7:0]temp;//温度
		wire [3:0]dang;//挡位
		wire [7:0]jishu40;//倒计时的值
		wire [1:0]dangc;//控制倒计时完控制风扇停止
		wire [0:0]mess;//检测是否按下倒计时的中间变量
		wire [7:0]jishucc;//倒计时器的值
	
		DivideClk#(.M(1_000),.N(500)) u2_DivideClk(clk_1kHz,1'b1,clk_1Hz);
		
		DivideClk#(.M(500),.N(250)) u3_DivideClk(clk_1kHz,1'b1,clk_2Hz);
		
		DivideClk#(.M(250),.N(125)) u4_DivideClk(clk_1kHz,1'b1,clk_4Hz);
		
		
     
		initemp m1(a1,a2,temp,clk_1kHz,sw1);  //改变温度
		inicount(a3,a4,jishucc,clk_1kHz);
		counterst(a5,mess,clk_1kHz);
		
		counter40 m7(jishu40,clk_1Hz,dangc,mess,jishucc);
		
	                   //风扇定时模式
		temptotime m2(temp,dang,clk_1kHz,dangc);  //将温度对应挡位
		dangwei m3(dang,cpc,clk_1kHz);//将挡位对应到时钟
		counter8 m0(jishu,clk_1kHz);
		tcount m4(kind,cpc);//用分出来的频做计数器
		transs m5(kind,row,col_r,col_g,jishu,sw1);
		
	   dealst m8(clk_1kHz,dang,temp,jishu40,jishucc,seg_led1,cat,sw1);//处理数据 
		
endmodule
module ssww(input sw1,input clk_1kHz,output reg k);
wire ccs=clk_1kHz|sw1;
always@(posedge ccs)begin if(sw1)begin k<=1;end
else begin k<=0;end
end
endmodule
module SEG1(                  //显示模块
	input [3:0] numI,
	output reg [7:0] seg0
);
	always@(numI) case(numI)
	   4'b0000: seg0 <= 8'b0011_1111;
	   4'b0001: seg0 <= 8'b0000_0110;
		4'b0010: seg0 <= 8'b0101_1011;
		4'b0011: seg0 <= 8'b0100_1111;
		4'b0100: seg0 <= 8'b0110_0110;
		4'b0101: seg0 <= 8'b0110_1101;
		4'b0110: seg0 <= 8'b0111_1101;
		4'b0111: seg0 <= 8'b0000_0111;
		4'b1000: seg0 <= 8'b0111_1111;
		4'b1001: seg0 <= 8'b0110_1111;
        default: seg0<=8'h00;
        endcase
endmodule

module dealst (                 //传递给显示模块的数据处理模块
    input clk,
	 input [3:0]data4,
    input [7:0] data1,data2,data3,//传入的数据
    output [7:0] seg0,
	 output reg[7:0] cat,
	 input sw1
);
    reg [2:0] i = 0;
	reg [3:0]data ;
	SEG1 n1(data,seg0);
	always @(posedge clk ) begin
		if(i==3'b110) begin
		i=3'b000;
		end
		else begin
		i = i+3'b001;
		end
		end
	
	always@( i)begin
	if(sw1==1)begin
	case (i)
	3'b000: begin cat<= 8'b1111_1101;data = data1[7:4];end
	3'b001: begin cat<= 8'b1111_1110;data = data1[3:0];end
	3'b010: begin cat<= 8'b1101_1111;data = data2[7:4];end
	3'b011: begin cat<= 8'b1110_1111;data = data2[3:0];end
	3'b100: begin cat<= 8'b1111_0111;data = data3[7:4];end
	3'b101: begin cat<= 8'b1111_1011;data = data3[3:0];end
	3'b110: begin cat<= 8'b0111_1111;data = data4[3:0];end
	default :begin cat<=8'b1111_1111;end
	endcase
	end
	else begin cat<= 8'b1111_1111;end
	end
endmodule



module dangwei(input wire[3:0]dang,output reg cpc,input clk_1kHz);             //挡位对应转换频率
DivideClk#(.M(1_000),.N(500)) u2_DivideClk(clk_1kHz,1'b1,clk_1Hz);
DivideClk#(.M(500),.N(250)) u3_DivideClk(clk_1kHz,1'b1,clk_2Hz);
DivideClk#(.M(250),.N(125)) u4_DivideClk(clk_1kHz,1'b1,clk_4Hz);
	
always @(posedge clk_1kHz)
begin
if (dang==4'b0001)
   begin
   cpc<=clk_1Hz;
   end
else if (dang==4'b0010)
   begin
	cpc<=clk_2Hz;
   end
else if (dang==4'b0011)
   begin
	cpc<=clk_4Hz;
	end
else 
   begin 
   cpc<=4'b0000;
	end
end

endmodule




module temptotime(input wire[7:0]temp,output reg[3:0] dang,input clk_1kHz,input wire[1:0]dangc);//温度和特定挡位对应
always @(posedge clk_1kHz)
begin
if(dangc==1)begin dang = 4'b0100;end//倒计时过来的dangc控制时间到完后停止
else begin
if(temp[7:4]==4'b0010)
begin
  if(temp[3:0]< 4'b0101)//小于25度
  begin
  dang = 4'b0001;
  end
  else  
  begin
  dang = 4'b0010;
  end
end
else if(temp[7:4]==4'b0011)
begin
  dang = 4'b0011;//30度到39度
end
else if(temp[7:4]== 4'b0100)
begin
  dang = 4'b0011;//40度到50度
end
else 
begin
  dang = 4'b0100;
end
end
end
endmodule










module initemp(input a1,input a2,output reg[7:0] temp,input clk_1kHz,sw1);//初始化温度，更改温度
wire BP1,BP2;

Debounce as(clk_1kHz,a1,BP1);
Debounce rfrf(clk_1kHz,a2,BP2);
initial begin
		temp <=8'b00100000;
		end
wire in = BP1|BP2;
always@(posedge in)// BP1 or posedge BP2 )
begin
if(sw1==1)begin
if(BP1)
  begin
    if(temp[3:0]==9)begin temp[3:0]<=0;temp[7:4]<=temp[7:4]+1;end
		
    else begin temp[3:0]<=temp[3:0]+1;end
  end
else if(BP2)
   begin
	if(temp[3:0]==0)begin temp[3:0]<=9;temp[7:4]<=temp[7:4]-1;end
		
    else begin temp[3:0]<=temp[3:0]-1;end
  end
  end
  else if (sw1==0)begin temp <=8'b00100000;end
end
endmodule  //将温度初始化成20度

module inicount(input a1,input a2,output reg[7:0] temp,input clk_1kHz);//倒计时器更改
wire BP1,BP2;

Debounce as(clk_1kHz,a1,BP1);
Debounce rfrf(clk_1kHz,a2,BP2);
initial begin
		temp <=8'b00110000;
		end
wire in = BP1|BP2;
always@(posedge in)// BP1 or posedge BP2 )
begin
if(BP1)
  begin
    if(temp[3:0]==9)begin temp[3:0]<=0;temp[7:4]<=temp[7:4]+1;end
		
    else begin temp[3:0]<=temp[3:0]+1;end
  end
else if(BP2)
   begin
	if(temp[3:0]==0)begin temp[3:0]<=9;temp[7:4]<=temp[7:4]-1;end
		
    else begin temp[3:0]<=temp[3:0]-1;end
  end
end
endmodule  //将温度初始化成20度




module tcount(output reg[1:0]kind, input cpc);//控制四个状态转换

    initial begin
		kind <=2'b00;
		end
      always @(posedge cpc)
      if(kind==2'b11)
		kind <=2'b00;
		else
		kind <= kind + 2'b01;
		
endmodule

module counter8(output reg[2:0]count, input cp);//控制单个状态
   initial begin
		count <= 3'b000;
		end
		always @(posedge cp)
			if(count==3'b111) count<=3'b000;
			else count<=count+1'b1;
endmodule

module counterst(input a5,output reg[0:0]mess,input clk_1kHz );//倒计时开始模块
wire BP5;
Debounce asss(clk_1kHz,a5,BP5);
initial begin mess<=1'b0;end
wire iii = BP5|clk_1kHz;
always@(iii)
 begin
 if(BP5)begin
if(mess==0)begin
 mess<=mess+1;
          end
 else begin mess<=0;end
 end
 else begin mess<=mess;end
 end
 endmodule
module counter40(output reg[7:0]count, input cp,output reg[1:0] dangc,input wire[0:0]mess,input [7:0]cc);


initial begin count<=8'b01000000;dangc<=2'b00;end
  always @(posedge cp )
		begin
		if(mess==1'b1)begin count<=cc;end
		else if (mess==1'b0)begin
		if(count[7:0]==8'b00000001)begin  dangc <= 2'b01;end
		else begin
		if(count[3:0] == 4'd0) 
		begin
		count[3:0] <= 4'd9;//个位满九时置零
		if(count[7:4] == 4'd0)
		begin
		count[7:4] <= 4'd3;//十位满3时清零
		end
		else count[7:4] <= count[7:4] - 1'b1; //十位加一
		end
		else count[3:0] <= count[3:0] - 1'b1; //个位加一
		end
		end
end
endmodule


module transs(input [1:0]cntt,output reg[7:0]row,col_r,col_g,input [2:0]cnt,input sw1);//状态变换模块

   always @(cnt) begin
	if(sw1==1)begin
		  if(cntt==2'b00) begin
				  case(cnt)
				3'b111: begin row<=8'b01111111;col_r<=8'b00000001;col_g<=8'b10000000;end
				3'b110: begin row<=8'b10111111;col_r<=8'b00000010;col_g<=8'b01000000;end
				3'b101: begin row<=8'b11011111;col_r<=8'b00000100;col_g<=8'b00100000;end
				3'b100: begin row<=8'b11101111;col_r<=8'b00001000;col_g<=8'b00010000;end
				3'b011: begin row<=8'b11110111;col_r<=8'b00010000;col_g<=8'b00001000;end
				3'b010: begin row<=8'b11111011;col_r<=8'b00100000;col_g<=8'b00000100;end
				3'b001: begin row<=8'b11111101;col_r<=8'b01000000;col_g<=8'b00000010;end
				3'b000: begin row<=8'b11111110;col_r<=8'b10000000;col_g<=8'b00000001;end
				  endcase
				  end

		   else if (cntt==2'b01) begin 
				case(cnt)
				3'b111: begin row<=8'b01111111;col_r<=8'b00001000;col_g<=8'b00000000;end
				3'b110: begin row<=8'b10111111;col_r<=8'b00001000;col_g<=8'b00000000;end
				3'b101: begin row<=8'b11011111;col_r<=8'b00001000;col_g<=8'b00000000;end
				3'b100: begin row<=8'b11101111;col_r<=8'b00001000;col_g<=8'b11110000;end
				3'b011: begin row<=8'b11110111;col_r<=8'b00010000;col_g<=8'b00001111;end
				3'b010: begin row<=8'b11111011;col_r<=8'b00010000;col_g<=8'b00000000;end
				3'b001: begin row<=8'b11111101;col_r<=8'b00010000;col_g<=8'b00000000;end
				3'b000: begin row<=8'b11111110;col_r<=8'b00010000;col_g<=8'b00000000;end
				endcase;
				 end


		   else if (cntt==2'b10) begin 
				case(cnt)
            3'b111: begin row<=8'b01111111;col_r<=8'b10000000;col_g<=8'b00000001;end
				3'b110: begin row<=8'b10111111;col_r<=8'b01000000;col_g<=8'b00000010;end
				3'b101: begin row<=8'b11011111;col_r<=8'b00100000;col_g<=8'b00000100;end
				3'b100: begin row<=8'b11101111;col_r<=8'b00010000;col_g<=8'b00001000;end
				3'b011: begin row<=8'b11110111;col_r<=8'b00001000;col_g<=8'b00010000;end
				3'b010: begin row<=8'b11111011;col_r<=8'b00000100;col_g<=8'b00100000;end
				3'b001: begin row<=8'b11111101;col_r<=8'b00000010;col_g<=8'b01000000;end
				3'b000: begin row<=8'b11111110;col_r<=8'b00000001;col_g<=8'b10000000;end
				endcase;
	 end

         else
				case(cnt)
				3'b111: begin row<=8'b01111111;col_r<=8'b00000000;col_g<=8'b00001000;end
				3'b110: begin row<=8'b10111111;col_r<=8'b00000000;col_g<=8'b00001000;end
				3'b101: begin row<=8'b11011111;col_r<=8'b00000000;col_g<=8'b00001000;end
				3'b100: begin row<=8'b11101111;col_r<=8'b11110000;col_g<=8'b00001000;end
				3'b011: begin row<=8'b11110111;col_r<=8'b00001111;col_g<=8'b00010000;end
				3'b010: begin row<=8'b11111011;col_r<=8'b00000000;col_g<=8'b00010000;end
				3'b001: begin row<=8'b11111101;col_r<=8'b00000000;col_g<=8'b00010000;end
				3'b000: begin row<=8'b11111110;col_r<=8'b00000000;col_g<=8'b00010000;end
				endcase;	
end
else begin row<=8'b11111111;col_r<=8'b00000000;col_g<=8'b00000000;end
end

endmodule


module DivideClk(
	input clkI,
	input enable,//0时关闭计算器,且归零
	output reg clkO
);
//	parameter WIDTH = 24;
	parameter M = 1_000_000;
	parameter N = 500_000;
	localparam WIDTH = $clog2(M+1);
	
	reg [WIDTH-1:0] r=1;//在1->M中循环
	
	always @ (posedge clkI or negedge enable) begin
		if(!enable) begin//未启用,全部置零
			clkO <= 1'b0;
			r <= 1'b1;
		end else begin
			clkO <= r>=N || r==M;
			if(r==M)
				r<=1'b1;
			else 
				r<=r+1'b1;
		end
	end
endmodule
module Debounce(clk,I,O);
	parameter Size = 1;
	parameter ClkSpeed = 1_000;//传入时钟速度

	input clk;
	input [Size-1:0] I;
	output reg [Size-1:0] O;
	
	reg [Size-1:0] pre,now;
	always @ (posedge clk) begin
		pre <=now;
		now <= I;
	end
	wire clkEnable = ~|(pre^now);
	wire clkO;
	DivideClk #(.M(ClkSpeed/50),.N(ClkSpeed/52)) u_DivideClk(clk,clkEnable,clkO);//20ms延时器
	initial O=I;
	always @(posedge clkO) O=pre;
endmodule


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity vga_signal_gen is
    port (
        clk_pix, rst_n: in std_logic;
        x_point, y_point, color_num: in std_logic_vector(7 downto 0);
        hor_sync, ver_sync, de: out std_logic;
        vga_r, vga_g, vga_b: out std_logic_vector(7 downto 0)
    );
end entity vga_signal_gen;

architecture bhv of vga_signal_gen is
    signal hor_sync_tmp, ver_sync_tmp: std_logic; -- horizontal& vertical sync register
    signal hor_sync_delay_tmp, ver_sync_delay_tmp: std_logic; -- delay 1 clock of sync register
    signal hor_cnt: integer range 0 to 3000; -- horizontal counter
    signal ver_cnt: integer range 0 to 2000; -- vertical counter
    signal x_cur_pos: integer range 0 to 3000; -- video x position
    signal y_cur_pos: integer range 0 to 2000; -- video y position
    signal vga_r_tmp, vga_g_tmp, vga_b_tmp: std_logic_vector(7 downto 0); -- color data register
    signal h_active_flag, v_active_flag: std_logic; -- horizontal& vertical video active flag
    signal video_active_flag: std_logic; -- video active (when horizontal active and vertical active)
    signal video_active_flag_delay: std_logic; -- delay 1 clock of video active flag
    signal delta: integer range 0 to 7;
    -- 800*600 at 60fps, clk_pix= 40MHz
        signal h_active: integer range 0 to 2000; -- horizontal active time (pixels)
        signal h_blank_fproch: integer range 0 to 120; -- horizontal front porch (pixels)
        signal h_blank_sync: integer range 0 to 200; -- horizontal sync time(pixels)
        signal h_blank_bproch: integer range 0 to 350; -- horizontal back porch (pixels)
        signal v_active: integer range 0 to 2000; -- vertical active Time (lines)
        signal v_blank_fproch: integer range 0 to 7; -- vertical front porch (lines)
        signal v_blank_sync: integer range 0 to 7; -- vertical sync time (lines)
        signal v_blank_bproch: integer range 0 to 60; -- vertical back porch (lines)
        signal h_total: integer range 0 to 3000; -- horizontal total time (pixels)
        signal v_total: integer range 0 to 3000; -- vertical total time (lines)
    -- define rgb value of 32 colors
        constant color_1_r: std_logic_vector(7 downto 0):= x"ff";
        constant color_1_g: std_logic_vector(7 downto 0):= x"ff";
        constant color_1_b: std_logic_vector(7 downto 0):= x"ff";
        constant color_2_r: std_logic_vector(7 downto 0):= x"00";
        constant color_2_g: std_logic_vector(7 downto 0):= x"00";
        constant color_2_b: std_logic_vector(7 downto 0):= x"00";
        constant color_3_r: std_logic_vector(7 downto 0):= x"aa";
        constant color_3_g: std_logic_vector(7 downto 0):= x"aa";
        constant color_3_b: std_logic_vector(7 downto 0):= x"aa";
        constant color_4_r: std_logic_vector(7 downto 0):= x"55";
        constant color_4_g: std_logic_vector(7 downto 0):= x"55";
        constant color_4_b: std_logic_vector(7 downto 0):= x"55";
        constant color_5_r: std_logic_vector(7 downto 0):= x"fe";
        constant color_5_g: std_logic_vector(7 downto 0):= x"d3";
        constant color_5_b: std_logic_vector(7 downto 0):= x"c7";
        constant color_6_r: std_logic_vector(7 downto 0):= x"ff";
        constant color_6_g: std_logic_vector(7 downto 0):= x"c4";
        constant color_6_b: std_logic_vector(7 downto 0):= x"ce";
        constant color_7_r: std_logic_vector(7 downto 0):= x"fa";
        constant color_7_g: std_logic_vector(7 downto 0):= x"ac";
        constant color_7_b: std_logic_vector(7 downto 0):= x"8e";
        constant color_8_r: std_logic_vector(7 downto 0):= x"ff";
        constant color_8_g: std_logic_vector(7 downto 0):= x"8b";
        constant color_8_b: std_logic_vector(7 downto 0):= x"83";
        constant color_9_r: std_logic_vector(7 downto 0):= x"f4";
        constant color_9_g: std_logic_vector(7 downto 0):= x"43";
        constant color_9_b: std_logic_vector(7 downto 0):= x"36";
        constant color_10_r: std_logic_vector(7 downto 0):= x"e9";
        constant color_10_g: std_logic_vector(7 downto 0):= x"1e";
        constant color_10_b: std_logic_vector(7 downto 0):= x"63";
        constant color_11_r: std_logic_vector(7 downto 0):= x"e2";
        constant color_11_g: std_logic_vector(7 downto 0):= x"66";
        constant color_11_b: std_logic_vector(7 downto 0):= x"9e";
        constant color_12_r: std_logic_vector(7 downto 0):= x"9c";
        constant color_12_g: std_logic_vector(7 downto 0):= x"27";
        constant color_12_b: std_logic_vector(7 downto 0):= x"b0";
        constant color_13_r: std_logic_vector(7 downto 0):= x"67";
        constant color_13_g: std_logic_vector(7 downto 0):= x"3a";
        constant color_13_b: std_logic_vector(7 downto 0):= x"b7";
        constant color_14_r: std_logic_vector(7 downto 0):= x"3f";
        constant color_14_g: std_logic_vector(7 downto 0):= x"51";
        constant color_14_b: std_logic_vector(7 downto 0):= x"b5";
        constant color_15_r: std_logic_vector(7 downto 0):= x"00";
        constant color_15_g: std_logic_vector(7 downto 0):= x"46";
        constant color_15_b: std_logic_vector(7 downto 0):= x"70";
        constant color_16_r: std_logic_vector(7 downto 0):= x"05";
        constant color_16_g: std_logic_vector(7 downto 0):= x"71";
        constant color_16_b: std_logic_vector(7 downto 0):= x"97";
        constant color_17_r: std_logic_vector(7 downto 0):= x"21";
        constant color_17_g: std_logic_vector(7 downto 0):= x"96";
        constant color_17_b: std_logic_vector(7 downto 0):= x"f3";
        constant color_18_r: std_logic_vector(7 downto 0):= x"00";
        constant color_18_g: std_logic_vector(7 downto 0):= x"bc";
        constant color_18_b: std_logic_vector(7 downto 0):= x"d4";
        constant color_19_r: std_logic_vector(7 downto 0):= x"3b";
        constant color_19_g: std_logic_vector(7 downto 0):= x"e5";
        constant color_19_b: std_logic_vector(7 downto 0):= x"db";
        constant color_20_r: std_logic_vector(7 downto 0):= x"97";
        constant color_20_g: std_logic_vector(7 downto 0):= x"fd";
        constant color_20_b: std_logic_vector(7 downto 0):= x"dc";
        constant color_21_r: std_logic_vector(7 downto 0):= x"16";
        constant color_21_g: std_logic_vector(7 downto 0):= x"73";
        constant color_21_b: std_logic_vector(7 downto 0):= x"00";
        constant color_22_r: std_logic_vector(7 downto 0):= x"37";
        constant color_22_g: std_logic_vector(7 downto 0):= x"a9";
        constant color_22_b: std_logic_vector(7 downto 0):= x"3c";
        constant color_23_r: std_logic_vector(7 downto 0):= x"89";
        constant color_23_g: std_logic_vector(7 downto 0):= x"e6";
        constant color_23_b: std_logic_vector(7 downto 0):= x"42";
        constant color_24_r: std_logic_vector(7 downto 0):= x"d7";
        constant color_24_g: std_logic_vector(7 downto 0):= x"ff";
        constant color_24_b: std_logic_vector(7 downto 0):= x"07";
        constant color_25_r: std_logic_vector(7 downto 0):= x"ff";
        constant color_25_g: std_logic_vector(7 downto 0):= x"f6";
        constant color_25_b: std_logic_vector(7 downto 0):= x"d1";
        constant color_26_r: std_logic_vector(7 downto 0):= x"f8";
        constant color_26_g: std_logic_vector(7 downto 0):= x"cb";
        constant color_26_b: std_logic_vector(7 downto 0):= x"8c";
        constant color_27_r: std_logic_vector(7 downto 0):= x"ff";
        constant color_27_g: std_logic_vector(7 downto 0):= x"eb";
        constant color_27_b: std_logic_vector(7 downto 0):= x"3b";
        constant color_28_r: std_logic_vector(7 downto 0):= x"ff";
        constant color_28_g: std_logic_vector(7 downto 0):= x"c1";
        constant color_28_b: std_logic_vector(7 downto 0):= x"07";
        constant color_29_r: std_logic_vector(7 downto 0):= x"ff";
        constant color_29_g: std_logic_vector(7 downto 0):= x"98";
        constant color_29_b: std_logic_vector(7 downto 0):= x"00";
        constant color_30_r: std_logic_vector(7 downto 0):= x"ff";
        constant color_30_g: std_logic_vector(7 downto 0):= x"57";
        constant color_30_b: std_logic_vector(7 downto 0):= x"22";
        constant color_31_r: std_logic_vector(7 downto 0):= x"b8";
        constant color_31_g: std_logic_vector(7 downto 0):= x"3f";
        constant color_31_b: std_logic_vector(7 downto 0):= x"27";
        constant color_32_r: std_logic_vector(7 downto 0):= x"79";
        constant color_32_g: std_logic_vector(7 downto 0):= x"55";
        constant color_32_b: std_logic_vector(7 downto 0):= x"48";
        constant color_back_r: std_logic_vector(7 downto 0):= x"f0";
        constant color_back_g: std_logic_vector(7 downto 0):= x"f0";
        constant color_back_b: std_logic_vector(7 downto 0):= x"f0";
        constant color_sel_r: std_logic_vector(7 downto 0):= x"ff";
        constant color_sel_g: std_logic_vector(7 downto 0):= x"00";
        constant color_sel_b: std_logic_vector(7 downto 0):= x"00";

begin
    hor_sync<= hor_sync_delay_tmp;
    ver_sync<= ver_sync_delay_tmp;
    video_active_flag<= h_active_flag and v_active_flag;
    de<= video_active_flag_delay;
    vga_r<= vga_r_tmp;
    vga_g<= vga_g_tmp;
    vga_b<= vga_b_tmp;
    h_active<= 800; -- horizontal active time (pixels)
    h_blank_fproch<= 40; -- horizontal front porch (pixels)
    h_blank_sync<= 128; -- horizontal sync time(pixels)
    h_blank_bproch<= 88; -- horizontal back porch (pixels)
    v_active<= 600; -- vertical active Time (lines)
    v_blank_fproch<= 1; -- vertical front porch (lines)
    v_blank_sync<= 4; -- vertical sync time (lines)
    v_blank_bproch<= 23; -- vertical back porch (lines)
    h_total<= h_active+ h_blank_fproch+ h_blank_sync+ h_blank_bproch; -- horizontal total time (pixels)
    v_total<= v_active+ v_blank_fproch+ v_blank_sync+ v_blank_bproch; -- vertical total time (lines)
    delta<= 1;

    sync_active_flag_gen: process(clk_pix, rst_n)
    -- gen hor_sync, ver_sync and de signal
    begin
        if rst_n= '0' then
            hor_sync_delay_tmp<= '0';
            ver_sync_delay_tmp<= '0';
            video_active_flag_delay<= '0';
        elsif rising_edge(clk_pix) then
            hor_sync_delay_tmp<= hor_sync_tmp;
            ver_sync_delay_tmp<= ver_sync_tmp;
            video_active_flag_delay<= video_active_flag;
        end if;
    end process sync_active_flag_gen;

    hor_cnt_gen: process(clk_pix, rst_n)
    -- horizontal counter (maxcnt= h_total- 1)
    begin
        if rst_n = '0' then
            hor_cnt<= 0;
        elsif rising_edge(clk_pix) then
            if hor_cnt= h_total- 1 then
                hor_cnt<= 0;
            else
                hor_cnt<= hor_cnt+ 1;
            end if;
        end if;
    end process hor_cnt_gen;

    x_cur_pos_gen: process(clk_pix, rst_n)
    -- x position of active video
    begin
        if rst_n = '0' then
            x_cur_pos<= 0;
        elsif rising_edge(clk_pix) then
            if hor_cnt>= h_blank_fproch+ h_blank_sync+ h_blank_bproch- 1 then -- when video active
                x_cur_pos<= hor_cnt- (h_blank_fproch+ h_blank_sync+ h_blank_bproch- 1);
            else
                x_cur_pos<= x_cur_pos;
            end if;
        end if;
    end process x_cur_pos_gen;

    y_cur_pos_gen: process(clk_pix, rst_n)
    -- y position of active video
    begin
        if rst_n = '0' then
            y_cur_pos<= 0;
        elsif rising_edge(clk_pix) then
            if ver_cnt>= v_blank_fproch+ v_blank_sync+ v_blank_bproch- 1 then -- when video active
                y_cur_pos<= ver_cnt- (v_blank_fproch+ v_blank_sync+ v_blank_bproch- 1);
            else
                y_cur_pos<= y_cur_pos;
            end if;
        end if;
    end process y_cur_pos_gen;

    ver_cnt_gen: process(clk_pix, rst_n)
    -- vertical counter (maxcnt= v_total- 1)
    begin
        if rst_n = '0' then
            ver_cnt<= 0;
        elsif rising_edge(clk_pix) then
            if hor_cnt= h_blank_fproch- 1 then -- at hor_sync time
                if ver_cnt= v_total- 1 then
                    ver_cnt<= 0;
                else
                    ver_cnt<= ver_cnt+ 1;
                end if;
            else
                ver_cnt<= ver_cnt;
            end if;
        end if;
    end process ver_cnt_gen;

    hor_sync_gen: process(clk_pix, rst_n)
    -- horizontal sync
    begin
        if rst_n = '0' then
            hor_sync_tmp<= '0';
        elsif rising_edge(clk_pix) then
            if hor_cnt= h_blank_fproch- 1 then
                hor_sync_tmp<= '1'; -- horizontal sync start
            elsif hor_cnt= h_blank_fproch+ h_blank_sync- 1 then
                hor_sync_tmp<= not hor_sync_tmp; -- horizontal sync end
            else
                hor_sync_tmp<= hor_sync_tmp;
            end if;
        end if;
    end process hor_sync_gen;

    h_active_flag_gen: process(clk_pix, rst_n)
    -- horizontal active flag
    begin
        if rst_n = '0' then
            h_active_flag<= '0';
        elsif rising_edge(clk_pix) then
            if hor_cnt= h_blank_fproch+ h_blank_sync+ h_blank_bproch- 1 then
                h_active_flag<= '1'; -- horizontal active start
            elsif hor_cnt= h_total- 1 then
                h_active_flag<= '0'; -- horizontal active end
            else
                h_active_flag<= h_active_flag;
            end if;
        end if;
    end process h_active_flag_gen;

    ver_sync_gen: process(clk_pix, rst_n)
    -- vertical sync
    begin
        if rst_n = '0' then
            ver_sync_tmp<= '0';
        elsif rising_edge(clk_pix) then
            if (ver_cnt= v_blank_fproch- 1) and (hor_cnt= h_blank_fproch- 1) then
                ver_sync_tmp<= '1'; -- vertical sync start
            elsif (ver_cnt= v_blank_fproch+ v_blank_sync- 1) and (hor_cnt= h_blank_fproch- 1) then
                ver_sync_tmp<= not ver_sync_tmp; -- vertical sync end
            else
                ver_sync_tmp<= ver_sync_tmp;
            end if;
        end if;
    end process ver_sync_gen;

    v_active_flag_gen: process(clk_pix, rst_n)
    -- vertical active flag
    begin
        if rst_n = '0' then
            v_active_flag<= '0';
        elsif rising_edge(clk_pix) then
            if (ver_cnt= v_blank_fproch+ v_blank_sync+ v_blank_bproch- 1) and (hor_cnt= h_blank_fproch- 1) then
                v_active_flag<= '1'; -- vertical active start
            elsif (ver_cnt= v_total- 1) and (hor_cnt= h_blank_fproch- 1) then
                v_active_flag<= '0'; -- vertical active end
            else
                v_active_flag<= v_active_flag;
            end if;
        end if;
    end process v_active_flag_gen;

    img_gen: process(clk_pix, rst_n)
        variable x_tmp, y_tmp, color_tmp: integer range 0 to 70;
    begin
        if rst_n = '0' then
            vga_r_tmp<= x"00";
            vga_g_tmp<= x"00";
            vga_b_tmp<= x"00";
            x_tmp:= 65;
            y_tmp:= 1;
            color_tmp:= 1;
        elsif rising_edge(clk_pix) then
            if video_active_flag= '1' then
                x_tmp:= conv_integer(x_point);
                y_tmp:= conv_integer(y_point);
                color_tmp:= conv_integer(color_num);
                if (x_tmp<= 64 and y_tmp<= 64 and (x_cur_pos>= h_active*97/640+ x_tmp*h_active/128) and (y_cur_pos>= v_active*41/1080+ y_tmp*v_active/72) and (x_cur_pos< h_active*49/320+ x_tmp*h_active/128) and (y_cur_pos< v_active*11/270+ y_tmp*v_active/72)) then
                        --drawing area pointer
                        vga_r_tmp<= color_sel_r;
                        vga_g_tmp<= color_sel_g;
                        vga_b_tmp<= color_sel_b;
                elsif (x_tmp> 64 and y_tmp<= 16 and (x_cur_pos>= x_tmp*h_active*3/96- h_active*1211/960) and (y_cur_pos>= v_active/135+ y_tmp*v_active/18) and (x_cur_pos< x_tmp*h_active/48+ x_tmp*h_active/96- h_active*403/320) and (y_cur_pos< v_active/90+ y_tmp*v_active*3/54)) then
                        vga_r_tmp<= color_sel_r;
                        vga_g_tmp<= color_sel_g;
                        vga_b_tmp<= color_sel_b;
                elsif 
                else
                    vga_r_tmp<= color_back_r;
                    vga_g_tmp<= color_back_g;
                    vga_b_tmp<= color_back_b;
                end if;
            else
                vga_r_tmp<= x"00";
                vga_g_tmp<= x"00";
                vga_b_tmp<= x"00";    
            end if;
        end if;
    end process img_gen;
    
end architecture bhv;
library ieee;
use ieee.std_logic_1164.all;

entity tb_fsm is
end tb_fsm;

architecture test of tb_fsm is

    signal clk     : std_logic := '0';
    signal btnL    : std_logic := '0';
    signal btnR    : std_logic := '0';
    signal btnC    : std_logic := '0';
    signal btnU    : std_logic := '0';
    signal btnD    : std_logic := '0';
    signal SW0     : std_logic := '0';
    signal seg     : std_logic_vector(0 to 6);
    signal an      : std_logic_vector(3 downto 0);
    signal dp      : std_logic;

    -- Aici include componenta deBouncer și driver7seg după caz!
    component fsm
        port (
            clk     : in std_logic;
            btnL    : in std_logic;
            btnR    : in std_logic;
            btnC    : in std_logic;
            btnU    : in std_logic;
            btnD    : in std_logic;
            SW0     : in std_logic;
            seg     : out std_logic_vector(0 to 6);
            an      : out std_logic_vector(3 downto 0);
            dp      : out std_logic
        );
    end component;

begin

    -- Instanțiere DUT
    DUT: fsm
        port map (
            clk  => clk,
            btnL => btnL,
            btnR => btnR,
            btnC => btnC,
            btnU => btnU,
            btnD => btnD,
            SW0  => SW0,
            seg  => seg,
            an   => an,
            dp   => dp
        );

    -- Generare clk ~ 10ns (100MHz, dar folosești n foarte mic în FSM pentru simulare)
    process
    begin
        while now < 2 ms loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    -- Stimuli principali
    process
    begin
        -- Reset global la început
        btnC <= '1';
        wait for 20 ns;
        btnC <= '0';
        wait for 40 ns;

        -- Setezi ora: apeși L
        btnL <= '1'; wait for 10 ns; btnL <= '0';
        wait for 100 ns;

        -- Incrementezi ora: apeși R de 2 ori
        btnR <= '1'; wait for 10 ns; btnR <= '0'; wait for 50 ns;
        btnR <= '1'; wait for 10 ns; btnR <= '0'; wait for 50 ns;

        -- Treci la minute: apeși L
        btnL <= '1'; wait for 10 ns; btnL <= '0'; wait for 80 ns;
        -- Incrementezi minutul
        btnR <= '1'; wait for 10 ns; btnR <= '0'; wait for 40 ns;

        -- Ieși din setare: apeși L
        btnL <= '1'; wait for 10 ns; btnL <= '0'; wait for 80 ns;

        -- Afisezi secundele: apeși D
        btnD <= '1'; wait for 10 ns; btnD <= '0'; wait for 80 ns;

        -- Revii la hh:mm: apeși D iar
        btnD <= '1'; wait for 10 ns; btnD <= '0'; wait for 80 ns;

        -- Cronometru: ridici SW0
        SW0 <= '1'; wait for 40 ns;

        -- Pornești cronometru: apeși U
        btnU <= '1'; wait for 10 ns; btnU <= '0'; wait for 80 ns;

        -- Pui pe pauză cronometru: apeși U
        btnU <= '1'; wait for 10 ns; btnU <= '0'; wait for 80 ns;

        -- Dai reset la cronometru (btnC)
        btnC <= '1'; wait for 20 ns; btnC <= '0'; wait for 80 ns;

        -- Revii la ceas: cobori SW0
        SW0 <= '0'; wait for 40 ns;

        -- Din nou reset global (btnC)
        btnC <= '1'; wait for 20 ns; btnC <= '0';

        wait for 400 ns;
        wait;
    end process;

end test;

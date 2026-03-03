library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm is
    Port (
        clk   : in STD_LOGIC;
        btnL  : in STD_LOGIC; --setare ore minute
        btnR  : in STD_LOGIC;  --incrementare ore minute la ceas
        btnC  : in STD_LOGIC;  --reset
        btnU  : in STD_LOGIC; --pauza cronometru
        btnD  : in STD_LOGIC;  --din hh:mm in 00:ss la ceas
        SW0   : in STD_LOGIC;  --selectare mod
        seg   : out STD_LOGIC_VECTOR (0 to 6); 
        an    : out STD_LOGIC_VECTOR (3 downto 0);
        dp    : out STD_LOGIC 
    );
end fsm;

architecture Behavioral of fsm is

    component driver7seg is
    Port (
        clk    : in STD_LOGIC; 
        Din    : in STD_LOGIC_VECTOR (15 downto 0); --date pentru cele 4 cifre
        an     : out STD_LOGIC_VECTOR (3 downto 0); 
        seg    : out STD_LOGIC_VECTOR (0 to 6); 
        dp_in  : in STD_LOGIC_VECTOR (3 downto 0); 
        dp_out : out STD_LOGIC; 
        rst    : in STD_LOGIC  --reset pentru driver
    ); 
    end component driver7seg;
       
    component deBounce is
    port(
        clk        : in std_logic;
        rst        : in std_logic;
        button_in  : in std_logic;
        pulse_out  : out std_logic
    );
    end component;
    
    signal btnLd, btnRd : std_logic;  --semnale pt debounce

    --starile fsm
    type states is (
        display_time, set_hours, set_minutes, display_seconds, 
        crono_idle, crono_run, crono_pause
    );
    signal current_state : states; 

    constant n : integer := 10**8;   --frecventa pentru divizarea ceasului
    signal inc_hours, inc_min, inc_sec : std_logic;   
    signal inc_crono_sec : std_logic;     
    --ceas
    type sec is record
        u : integer range 0 to 9;
        t : integer range 0 to 5;
    end record;
    type min is record
        u : integer range 0 to 9;
        t : integer range 0 to 5;
    end record;
    type hours is record
        u : integer range 0 to 9;
        t : integer range 0 to 2;
    end record;
    type time is record
        hours : hours;
        min   : min;
        sec   : sec;
    end record;
    
    signal t : time := ((0,0),(0,0),(0,0));

    --crono
    type crono_type is record
        min : min;
        sec : sec;
    end record;
    signal crono : crono_type := ((0,0),(0,0));

    signal hours_min      : STD_LOGIC_VECTOR (15 downto 0); --hh:mm
    signal sec_sec        : STD_LOGIC_VECTOR (15 downto 0); --00:ss
    signal crono_min_sec  : STD_LOGIC_VECTOR (15 downto 0); --mm:ss
    signal d              : STD_LOGIC_VECTOR (15 downto 0); --data pt portare Din la 7seg
    signal clk1hz         : std_logic; --impuls la 1 Hz
    signal blink_hours, blink_min : std_logic;
    signal an_int         : std_logic_vector (3 downto 0); --semnal pt an 7seg
    signal show_seconds   : std_logic := '0';

begin

deb1 : deBounce port map (clk => clk, rst => '0', button_in => btnL, pulse_out => btnLd);
deb3 : deBounce port map (clk => clk, rst => '0', button_in => btnR, pulse_out => btnRd);

--fsm cu starile
state_register : process(btnC, clk)
    --copii pentru semnalele t si crono
    variable counter : integer := 0;      
    variable t_var : time;
    variable crono_var : crono_type;
begin
    t_var := t;
    crono_var := crono;

    --resetam tot la reset = 1
    if btnC = '1' then
        current_state <= display_time;
        t_var.hours.t := 0; t_var.hours.u := 0;
        t_var.min.t := 0;   t_var.min.u := 0;
        t_var.sec.t := 0;   t_var.sec.u := 0;
        crono_var.min.t := 0; crono_var.min.u := 0;
        crono_var.sec.t := 0; crono_var.sec.u := 0;
        show_seconds <= '0';
        counter := 0;
        inc_sec <= '1';
        inc_crono_sec <= '1';

    elsif rising_edge(clk) then
        --generare semnal pt incrementare secunde si resetare counter 
        if counter = n - 1 then
            counter := 0;
            inc_sec <= '1';
            inc_crono_sec <= '1';
        else 
            counter := counter + 1;
            inc_sec <= '0';
            inc_crono_sec <= '0';
        end if;

        --automat cu stari
        case current_state is
            --Ceasul
            when display_time =>
                if SW0 = '1' then --trecere in cronometru
                    current_state <= crono_idle;
                elsif btnLd = '1' then --setare ora
                    current_state <= set_hours;
                elsif btnD = '1' then  --afisare secunde
                    current_state <= display_seconds;
                    show_seconds <= '1';
                end if;

            when set_hours =>
                if SW0 = '1' then
                    current_state <= crono_idle;
                elsif btnLd = '1' then
                    current_state <= set_minutes;   --trecem aici la minute
                end if;

            when set_minutes =>
                if SW0 = '1' then
                    current_state <= crono_idle;
                elsif btnLd = '1' then
                    current_state <= display_time;  --dupa minute revenim la afisarea orei
                end if;

            when display_seconds =>
                if SW0 = '1' then
                    current_state <= crono_idle;
                elsif btnD = '1' then
                    current_state <= display_time;
                    show_seconds <= '0';   --afisare ore:minute
                end if;

            --cronomtrul
            when crono_idle =>
                if SW0 = '0' then
                    current_state <= display_time;
                elsif btnU = '1' then
                    current_state <= crono_run;   --start cronometru 
                elsif btnC = '1' then --resetare
                    crono_var.min.t := 0; crono_var.min.u := 0;
                    crono_var.sec.t := 0; crono_var.sec.u := 0;
                end if;

            when crono_run =>
                if SW0 = '0' then
                    current_state <= display_time;
                elsif btnU = '1' then
                    current_state <= crono_pause;    --pauza
                elsif btnC = '1' then
                    current_state <= crono_idle;   --reset si intoarcere la idle
                    crono_var.min.t := 0; crono_var.min.u := 0;
                    crono_var.sec.t := 0; crono_var.sec.u := 0;
                end if;

            when crono_pause =>
                if SW0 = '0' then
                    current_state <= display_time;
                elsif btnU = '1' then
                    current_state <= crono_run;   --reluare cronomtru
                elsif btnC = '1' then
                    current_state <= crono_idle; --reset si idle
                    crono_var.min.t := 0; crono_var.min.u := 0;
                    crono_var.sec.t := 0; crono_var.sec.u := 0;
                end if;

            when others =>
                current_state <= display_time;
        end case;  

        --incrementarea orei si a minutelor
        if current_state = set_minutes and btnRd = '1' then
            inc_min <= '1';
        else
            inc_min <= '0';
        end if;

        if current_state = set_hours and btnRd = '1' then
            inc_hours <= '1';
        else
            inc_hours <= '0';
        end if;

        --incrementare ceas
        if (inc_sec = '1' and current_state = display_time) then
            --incrementare secunde si cascadare la minute ore
            if t_var.sec.u = 9 then
                t_var.sec.u := 0;
                if t_var.sec.t = 5 then
                    t_var.sec.t := 0;
                    if t_var.min.u = 9 then
                        t_var.min.u := 0;
                        if t_var.min.t = 5 then
                            t_var.min.t := 0;
                            if t_var.hours.u = 3 and t_var.hours.t = 2 then
                                t_var.hours.u := 0;
                                t_var.hours.t := 0;
                            elsif t_var.hours.u = 9 then
                                t_var.hours.u := 0;
                                t_var.hours.t := t_var.hours.t + 1;
                            else 
                                t_var.hours.u := t_var.hours.u + 1;
                            end if;
                        else
                            t_var.min.t := t_var.min.t + 1;
                        end if;
                    else
                        t_var.min.u := t_var.min.u + 1;   
                    end if;
                else
                    t_var.sec.t := t_var.sec.t + 1; 
                end if;
            else 
                t_var.sec.u := t_var.sec.u + 1;
            end if;

        elsif inc_min = '1' then
            if t_var.min.u = 9 then
                t_var.min.u := 0;
                if t_var.min.t = 5 then
                    t_var.min.t := 0;
                else
                    t_var.min.t := t_var.min.t + 1;
                end if;
            else
                t_var.min.u := t_var.min.u + 1;   
            end if; 
        
        elsif inc_hours = '1' then
            if t_var.hours.u = 3 and t_var.hours.t = 2 then
                t_var.hours.u := 0;
                t_var.hours.t := 0;
            elsif t_var.hours.u = 9 then
                t_var.hours.u := 0;
                t_var.hours.t := t_var.hours.t + 1;
            else 
                t_var.hours.u := t_var.hours.u + 1;
            end if;
        end if;

        --incrementare cronometru
        if inc_crono_sec = '1' and current_state = crono_run then
            if crono_var.sec.u = 9 then
                crono_var.sec.u := 0;
                if crono_var.sec.t = 5 then
                    crono_var.sec.t := 0;
                    if crono_var.min.u = 9 then
                        crono_var.min.u := 0;
                        if crono_var.min.t = 5 then
                            crono_var.min.t := 0;
                        else
                            crono_var.min.t := crono_var.min.t + 1;
                        end if;
                    else
                        crono_var.min.u := crono_var.min.u + 1;
                    end if;
                else
                    crono_var.sec.t := crono_var.sec.t + 1;
                end if;
            else
                crono_var.sec.u := crono_var.sec.u + 1;
            end if;
        end if;
    end if;

    --dam variabilelor principale valoarea copiilor
    t <= t_var;
    crono <= crono_var;
end process;

--afisaj 7seg
--atribuim datelor 7seg valorile din incrementari
hours_min <= std_logic_vector(to_unsigned(t.hours.t,4)) &
             std_logic_vector(to_unsigned(t.hours.u,4)) &
             std_logic_vector(to_unsigned(t.min.t,4)) &
             std_logic_vector(to_unsigned(t.min.u,4));
sec_sec  <=  std_logic_vector(to_unsigned(0,4)) &
             std_logic_vector(to_unsigned(0,4)) &
             std_logic_vector(to_unsigned(t.sec.t,4)) &
             std_logic_vector(to_unsigned(t.sec.u,4));
crono_min_sec <= std_logic_vector(to_unsigned(crono.min.t,4)) &
                 std_logic_vector(to_unsigned(crono.min.u,4)) &
                 std_logic_vector(to_unsigned(crono.sec.t,4)) &
                 std_logic_vector(to_unsigned(crono.sec.u,4));

--in functie de ce stare avem afisam pe 7seg
with current_state select
    d <= crono_min_sec when crono_idle | crono_run | crono_pause,
         sec_sec        when display_seconds,
         hours_min      when others;

--port map 7seg
display : driver7seg port map (
    clk    => clk,
    Din    => d,
    an     => an_int,
    seg    => seg,
    dp_in  => (others => '0'),
    dp_out => dp, 
    rst    => btnC  
);

--blink pt cifre cand in starile de set ora sau set min
blink_hours <= '1' when current_state = set_hours else '0';
blink_min   <= '1' when current_state = set_minutes else '0';


--divizarea semnalului pentru obtinerea efectului de blink
div1Hz : process(btnC, clk)
    variable counter2 : integer := 0;
begin
    if btnC = '1' then
        counter2 := 0;
        clk1hz <= '0'; 
    elsif rising_edge(clk) then
        if counter2 = n/2 - 1 then
            counter2 := 0;
            clk1hz <= not clk1hz;
        else
            counter2 := counter2 + 1;
            clk1hz <= clk1hz;
        end if;  
    end if;    
end process;

--animarea efectului blink pe cifre
an(3) <= (an_int(3) or clk1hz) when blink_hours = '1' else an_int(3);
an(2) <= (an_int(2) or clk1hz) when blink_hours = '1' else an_int(2);
an(1) <= (an_int(1) or clk1hz) when blink_min   = '1' else an_int(1);
an(0) <= (an_int(0) or clk1hz) when blink_min   = '1' else an_int(0);

end Behavioral;
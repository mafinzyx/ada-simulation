-- Danylo Zherzdiev 196765, Danylo Lohachov, Vlad Sklema, - semester 3
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO;
with Ada.Numerics.Discrete_Random;

procedure Simulation is

   -- Global Variables
   Number_Of_Cooks: constant Integer := 10;
   Number_Of_Orders: constant Integer := 3;
   Number_Of_Waiters: constant Integer := 3;

   subtype Cook_Type is Integer range 1 .. Number_Of_Cooks;
   subtype Order_Type is Integer range 1 .. Number_Of_Orders;
   subtype Waiter_Type is Integer range 1 .. Number_Of_Waiters;

   -- Each Cook is assigned a dish that they prepare
Dish_Name: constant array (Cook_Type) of String(1 .. 8)
  := ("Salat   ", "Chicken ", "Tomato  ", "Cheese  ", "Spagetti",
      "Fish    ", "Steak   ", "Soup    ", "Burger  ", "Pasta   ");


   -- Order is a combination of dishes
   Order_Name: constant array (Order_Type) of String(1 .. 9)
     := ("Caeser   ", "Carbonara", "Pizza    ");

   -- Task Declarations
   -- Cook task
   task type Cook is
      entry Start(Cook_Number: in Cook_Type; Cooking_Time: in Integer);
   end Cook;

   -- Waiter task
   task type Waiter is
      entry Start(Waiter_Number: in Waiter_Type; Delivery_Time: in Integer);
   end Waiter;

   -- Kitchen receives dishes from cooks and delivers orders to waiters
   task type Kitchen is
      -- Accept a dish for storage (provided there's room)
      entry Store(Cook: in Cook_Type; Dish_Number: in Integer);
      -- Deliver an order (provided enough dishes are available)
      entry Deliver(Order: in Order_Type; Number: out Integer);
      -- Accept pest destruction request
      entry Pest_In_Storage(Product: in Cook_Type);
      entry Storage_Contents;
   end Kitchen;

   -- Pest task
   task type Pest is
      entry Start;
   end Pest;

   C: array (1 .. Number_Of_Cooks) of Cook;
   W: array (1 .. Number_Of_Waiters) of Waiter;
   K: Kitchen;
   P: Pest;

   -- Cook Task Body
   task body Cook is
      subtype Cooking_Time_Range is Integer range 1 .. 2;
      package Random_Cooking is new Ada.Numerics.Discrete_Random(Cooking_Time_Range);
      G: Random_Cooking.Generator;
      Cook_Type_Number: Integer;
      Dish_Number: Integer;
      Random_Time: Duration;
      -- For balancing
      Buffer_Threshold: constant Integer := 25; -- Example threshold
   begin
      accept Start(Cook_Number: in Cook_Type; Cooking_Time: in Integer) do
         Random_Cooking.Reset(G);
         Dish_Number := 1;
         Cook_Type_Number := Cook_Number;
      end Start;

      Put_Line("Cook: Started preparing " & Dish_Name(Cook_Type_Number));
      loop
         Random_Time := Duration(Random_Cooking.Random(G));
         delay Random_Time;
         Put_Line("Cook: Prepared dish " & Dish_Name(Cook_Type_Number) &
                    " number " & Integer'Image(Dish_Number));

         -- Store dish in kitchen with buffer management
         loop
            select
               K.Store(Cook_Type_Number, Dish_Number);
               Put_Line("Cook: Successfully stored dish " & Dish_Name(Cook_Type_Number) &
                          " number " & Integer'Image(Dish_Number));
               exit; -- Exit the inner loop after successful store
            or
               delay 2.0; -- Wait before retrying if store was unsuccessful
               Put_Line("Cook: Buffer full, retrying to store dish " & Dish_Name(Cook_Type_Number) &
                          " number " & Integer'Image(Dish_Number));
            end select;
         end loop;

         Dish_Number := Dish_Number + 1;
      end loop;
   end Cook;

   -- Waiter Task Body
   task body Waiter is
      subtype Delivery_Time_Range is Integer range 6 .. 10;
      package Random_Delivery is new Ada.Numerics.Discrete_Random(Delivery_Time_Range);
      package Random_Order is new Ada.Numerics.Discrete_Random(Order_Type);

      G: Random_Delivery.Generator;
      GA: Random_Order.Generator;
      Waiter_Nb: Waiter_Type;
      Order_Number: Integer;
      Delivery: Integer;
      Order_Type_Number: Integer;
      Waiter_Name: constant array (1 .. Number_Of_Waiters) of String(1 .. 6)
        := ("Danylo", "Danilo", "Vlad  ");
   begin
      accept Start(Waiter_Number: in Waiter_Type; Delivery_Time: in Integer) do
         Random_Delivery.Reset(G);
         Random_Order.Reset(GA);
         Waiter_Nb := Waiter_Number;
         Delivery := Delivery_Time;
      end Start;

      Put_Line("Waiter: Started working " & Waiter_Name(Waiter_Nb));
      loop
         delay Duration(Random_Delivery.Random(G)) + 2.0; -- Random delay
         Order_Type_Number := Random_Order.Random(GA); -- Random order selection

         -- Take an order for delivery
         K.Deliver(Order_Type_Number, Order_Number);

         if Order_Number = 0 then
            Put_Line("Waiter: Failed to pick up order " & Order_Name(Order_Type_Number));
         else
            Put_Line("Waiter: Picked up order " & Order_Name(Order_Type_Number) &
                     ", number " & Integer'Image(Order_Number));
         end if;
      end loop;
   end Waiter;

   -- Kitchen Task Body
   task body Kitchen is
      Storage_Capacity: constant Integer := 5;
      type Storage_Type is array (Cook_Type) of Integer;
      Storage: Storage_Type := (others => 0);
      Order_Content: array(Order_Type, Cook_Type) of Integer
        := ((2, 1, 2, 0, 2, 1, 0, 2, 1, 1),
            (1, 2, 0, 1, 0, 2, 1, 0, 2, 1),
            (3, 2, 2, 0, 1, 1, 2, 0, 1, 0));
      Max_Order_Content: array(Cook_Type) of Integer;
      Order_Number: array(Order_Type) of Integer := (others => 1);
      In_Storage: Integer := 0;

      -- Mutex for synchronization (optional for more complex scenarios)
      -- Ada provides implicit synchronization via tasking, so explicit mutexes are not necessary here.

      procedure Setup_Variables is
      begin
         for W in Cook_Type loop
            Max_Order_Content(W) := 0;
            for Z in Order_Type loop
               if Order_Content(Z, W) > Max_Order_Content(W) then
                  Max_Order_Content(W) := Order_Content(Z, W);
               end if;
            end loop;
         end loop;
      end Setup_Variables;

      function Can_Accept(Cook: Cook_Type) return Boolean is
      begin
         if In_Storage >= Storage_Capacity then
            return False;
         else
            return True;
         end if;
      end Can_Accept;

      function Can_Deliver(Order: Order_Type) return Boolean is
      begin
         for W in Cook_Type loop
            if Storage(W) < Order_Content(Order, W) then
               return False;
            end if;
         end loop;
         return True;
      end Can_Deliver;

      -- Renamed procedure to avoid conflict
      procedure Display_Storage_Contents is
      begin
         Put_Line("Checking storage capacity: " & Integer'Image(In_Storage) & " out of " & Integer'Image(Storage_Capacity));
         for W in Cook_Type loop
            if Storage(W) > 0 then
               Put_Line("| Storage contents: " & Integer'Image(Storage(W)) & " " & Dish_Name(W));
            else
               Put_Line("| Storage for " & Dish_Name(W) & " is empty.");
            end if;
         end loop;
         Put_Line("| Number of dishes in storage: " & Integer'Image(In_Storage));
      end Display_Storage_Contents;


      procedure Product_destruction(Product: Cook_Type) is
      begin
         Put_Line("Kitchen: Destroying all of " & Dish_Name(Product));
         In_Storage := In_Storage - Storage(Product);
         Storage(Product) := 0;
      end Product_destruction;

   begin
      Put_Line("Kitchen: Started");
      Setup_Variables;

      loop
         select
            accept Store(Cook: in Cook_Type; Dish_Number: in Integer) do
               if Can_Accept(Cook) then
                  Put_Line("Kitchen: Accepted dish " & Dish_Name(Cook) & " number " &
                           Integer'Image(Dish_Number));
                  Storage(Cook) := Storage(Cook) + 1;
                  In_Storage := In_Storage + 1;
               else
                  Put_Line("Kitchen: Rejected dish " & Dish_Name(Cook) & " number " &
                           Integer'Image(Dish_Number));
               end if;
            end Store;
         or
            accept Deliver(Order: in Order_Type; Number: out Integer) do
               if Can_Deliver(Order) then
                  Put_Line("Kitchen: Delivered order " & Order_Name(Order) & " number " &
                           Integer'Image(Order_Number(Order)));
                  for W in Cook_Type loop
                     Storage(W) := Storage(W) - Order_Content(Order, W);
                     In_Storage := In_Storage - Order_Content(Order, W);
                  end loop;
                  Number := Order_Number(Order);
                  Order_Number(Order) := Order_Number(Order) + 1;
               else
                  Put_Line("Kitchen: Lacking dishes for order " & Order_Name(Order));
                  Number := 0;
               end if;
            end Deliver;
         or
            accept Pest_In_Storage(Product: in Cook_Type) do
               Put_Line("Kitchen: Received pest destruction request for " & Dish_Name(Product));
               Product_destruction(Product);
            end Pest_In_Storage;
         or
            accept Storage_Contents do
               Display_Storage_Contents; -- Call the renamed procedure here
            end Storage_Contents;
         end select;
      end loop;
   end Kitchen;

   -- Pest Task Body
task body Pest is
    subtype Pest_Time_Range is Integer range 2 .. 5; -- Example duration range in seconds
    package Random_Pest_Time is new Ada.Numerics.Discrete_Random(Pest_Time_Range);
    G: Random_Pest_Time.Generator;
    Pest_Duration: Duration;
    Product_To_Destroy: Cook_Type;
    -- Random generator for selecting product to destroy
    subtype Product_Range is Integer range 1 .. Number_Of_Cooks;
    package Random_Product_Select is new Ada.Numerics.Discrete_Random(Product_Range);
    G_Product: Random_Product_Select.Generator;
begin
    accept Start do
        Random_Pest_Time.Reset(G);
        Random_Product_Select.Reset(G_Product);
    end Start;

    Put_Line("Pest: Started pest execution.");
    loop
        Pest_Duration := Duration(Random_Pest_Time.Random(G));
        delay Pest_Duration;

        -- Select a random product to destroy
        Product_To_Destroy := Random_Product_Select.Random(G_Product);

        -- Update the output text
        Put_Line("PEST ENTERED: this pest likes product " & Dish_Name(Product_To_Destroy) & " and will eat it.");

        -- Invoke Pest_In_Storage in Kitchen
        K.Pest_In_Storage(Product_To_Destroy);

        Put_Line("PEST RESULT: you have lost all stock of product " & Dish_Name(Product_To_Destroy) & ".");

        -- Display the current storage contents
        K.Storage_Contents; -- This will show the updated storage status after the pest's action
    end loop;
end Pest;


   -- "Main" Simulation
begin
   -- Start Kitchen and Pest
   -- (Kitchen starts automatically as a task object)

   -- Start Pest task
   P.Start;

   -- Start Cook tasks
   for I in 1 .. Number_Of_Cooks loop
      C(I).Start(I, 10);
   end loop;

   -- Start Waiter tasks
   for J in 1 .. Number_Of_Waiters loop
      W(J).Start(J, 12);
   end loop;

   -- Keep the main task alive indefinitely
   delay 1000.0; -- Adjust as needed for simulation duration
end Simulation;

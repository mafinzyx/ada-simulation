# Kitchen Simulation in Ada

This project simulates a restaurant kitchen environment, implemented in Ada. It includes tasks for cooks, waiters, a kitchen storage system, and a pest that introduces unexpected challenges. The simulation was developed as part of a semester project.
## Project Contributors
- **[Danylo Zherzdiev](https://github.com/mafinzyx)**
- **[Danylo Lohachov](https://github.com/eternaki)**
- **[Vlad Sklema](https://github.com/waldemarIT)**
## Overview

The simulation models a restaurant with the following components:

- **Cooks**: Prepare dishes and store them in the kitchen.
- **Waiters**: Pick up orders and deliver them to customers.
- **Kitchen Storage**: Manages dish availability and handles stock for orders.
- **Pest**: Periodically destroys random dishes in storage, simulating real-world inventory issues.

The simulation demonstrates Ada’s tasking capabilities by using concurrent processes to simulate the real-time activities and interactions of these entities.

## Simulation Structure

### Components

- **Cooks**: Each cook is responsible for one type of dish (e.g., Chicken, Spaghetti). Cooks prepare dishes with random time delays, attempt to store them in the kitchen, and retry if the storage is full.
  
- **Waiters**: Waiters pick up orders consisting of a random combination of dishes. They check if the kitchen has enough stock to fulfill an order and deliver it if possible, with delays simulating delivery time.
  
- **Kitchen**: The kitchen manages dish storage, fulfills orders, and allows pest destruction when requested. Storage is limited, with each dish having its own count.
  
- **Pest**: The pest randomly targets a dish type, clearing all stock for that dish in the kitchen storage, simulating unexpected losses.

### Task Flow

1. Cooks start preparing and storing their assigned dishes.
2. Waiters select orders, check for availability, and deliver them if fully stocked.
3. The kitchen coordinates dish storage and order fulfillment, ensuring stock levels.
4. The pest randomly clears stock for a specific dish type, affecting the kitchen's inventory.

## Technical Details

- **Concurrency**: Ada tasks represent each cook, waiter, the kitchen, and pest, illustrating Ada’s concurrency model.
  
- **Random Timing**: Cooks, waiters, and pests have randomized delays, adding variability to the simulation.
  
- **Storage Management**: The kitchen manages limited storage space, with checks on dish capacity and stock levels.

## How to Run

1. **Install Ada**: Make sure you have an Ada compiler installed, like GNAT.
  
2. **Clone the Repository**:
   ```bash
   git clone https://github.com/mafinzyx/ada-simulation.git
   cd ada-simulation
3. **Compile**
   ```bash
   gnatmake simulation.adb
4. **Run the Simulation:
   ```bash
   ./simulation

# Highrise Mafia Game

This repo contains an implementation of the [social deception party game "Mafia"](https://en.wikipedia.org/wiki/Mafia_(party_game)) in Highrise.

The gameplay works like this:

- First, wait until there are at least 4 players and a few seconds have elapsed.
- Randomly assign players roles: townsperson, detective, or mafioso
    - If there are at least 6 players, then one third of players are mafiosos (rounded); otherwise there is one mafioso.
    - There is always one detective.
    - All other players are townspeople.
    - Townspeople and detectives are on the same team.
- The clock cycles between day (yellow floor) and night (blue floor).
- During night time:
    - Detectives can choose a character to learn what their role is
    - Mafiosos can choose someone to murder (unanimously)
- During day time:
    - All players can vote on someone to execute.
    - When the day ends, the player with the most votes is killed (if at least 2 people voted for them).
    - If there is a tie with two or more votes each, all tied players will die.
- The townspeople win if all mafia are eliminated.
- The mafia win if enough townspeople/detectives are eliminated to the point where at least half of players are mafia (and they can kill with impugnity).

## Script Layout

- [Scripts/GameController.lua](Assets/Scripts/GameController.lua): The main game controller that handles assigning player roles, disseminating information, moving between game phases, and so on.
    - The game controller has most of the gameplay logic.
    - Game state is tracked in `currentState`, which acts as a state machine using a tagged enumeration.
    - Player roles are tracked in `roles`, which map each player to their role (mafioso, townsperson, detective, corpse, observer) and team (mafia, citizens, neutral).
    - The game controller also handles broadcasting news events to clients when needed.
- [Scripts/News.lua](Assets/Scripts/News.lua): A module that handles sending event updates to player clients so it can be displayed to players.
    - The news module defines a `NewsEvent` type that specifies which types of events are sent to clients.
    - Some events are sent to everyone (e.g. `new_game`), while others are selectively sent to some players (e.g. `role_revealed`).
    - Various different client scripts listen for various different news events that the particular script cares about.
- [Scripts/DayNightCycle.lua](Assets/Scripts/DayNightCycle.lua): A client script that makes the floor switch between yellow and blue for the day/night cycle.
- [Scripts/TargetManager.lua](Assets/Scripts/TargetManager.lua): A module that governs the logic for when players click on another player to target them and displaying the target crosshairs.
- [Scripts/Teleporter.lua](Assets/Scripts/Teleporter.lua): A module to handle teleporting players (used to move between the game area and the observation deck).
- [Scripts/UI/HUD.lua](Assets/Scripts/UI/HUD.lua): The heads-up display information for the player, which includes the display of the player's role, the current game phase, and the news event feed.
- [Scripts/UI/RoleLabel.lua](Assets/Scripts/UI/RoleLabel.lua): The floating UI above each player's head that displays their username and their role (if known).
- [Scripts/UI/SimpleTextDisplay.lua](Assets/Scripts/UI/SimpleTextDisplay.lua): A UI to show a simple text label (for the "Observation Deck" and "Game Area" signs).
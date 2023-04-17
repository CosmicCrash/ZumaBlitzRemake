Zuma Blitz Remake
==========

A preservation & recreation project for Zuma Blitz - an old Facebook game
from 2010-2017, specifically the Kroakatoa Island update.

Zuma Blitz was a Facebook game that used Adobe Flash, from 2010-2017. It
released on December 14, 2010. It then had a revamp in 2012, called
Kroakatoa Island, and was closed March 31, 2017.

This project is a collaborative effort in order for past Zuma Blitz players
to relive their 1-minute ball shooting memories.

==========

This is still in it's early development stages. Changes may occur, and there's
still a whole lot of features to implement, such as:
- Board Selector
- Powers Selector
- Food Selector
- Spirit Animal prompts
- Frogatars

Keep in mind that it's possible to change some of these values.

To change the board:
Currently, the available boards are:
- Journey to Kroakatoa
- Bronze Board (Bronze Age)
- Crab Board (Crab Snap)
- Roots Board (Back to your Roots)

- Double click on the games folder
- Double click on the ZumaBlitzRemake folder
- Double click on the config folder
- Open "level_set.json" with Notepad. If you do not see this please open the game and enter your name, and click on Close
- Find the number 101. Replace it with anything here below:
  - 101: Roots Board
  - 102: Bronze Board
  - 103: Journey to Kroakatoa
  - 104: Crab Board

To assign a Spirit Animal:
Make sure you already have a profile.

- Double click on the games folder
- Double click on the ZumaBlitzRemake folder
- Double click on "runtime.json"
- Scroll down until you're inside your profile:

  "selected": "YourName",
  "profiles": {
      "YourName": {
          ...
          "foodInventory": [],
          "monument": "eagle", <-- ADD IT HERE, it can be "eagle" or "turtle"
                                   MAKE SURE IT IS ENCAPSULATED IN QUOTES AND IT HAS
                                   A COMMA AFTER THAT
          "levels" {
              ...
          }
          ...
      }
  }

To stop using a Spirit Animal, simply remove the line that says "monument".

To assign Food:
Make sure you already have a profile.

- Double click on the games folder
- Double click on the ZumaBlitzRemake folder
- Double click on "runtime.json"
- Scroll down until you're inside your profile:

  "selected": "YourName",
  "profiles": {
      "YourName": {
          ...
          "foodInventory": [],
          "food": "curvy_fries", <-- ADD IT HERE, it can be in the valid values below:
                                     MAKE SURE IT IS ENCAPSULATED IN QUOTES AND IT HAS
                                     A COMMA AFTER THAT
          "levels" {
              ...
          }
          ...
      }
  }

Valid values:
- "cherry_time_tart"
- "chocolate_love"
- "curvy_fries"
- "kiwi_kebab"
- "10_pound_turkey"
- "chocolate_food" (note that increased shot speed only applies and it doesn't give a Candy Lei effect)

To stop using Food, simply remove the line that says "food".

To upgrade Powers:
Make sure you already have a profile.

- Double click on the games folder
- Double click on the ZumaBlitzRemake folder
- Double click on "runtime.json"
- Scroll down until you're inside your profile:

  "selected": "YourName",
  "profiles": {
      "YourName": {
          ...
          "equippedFood": "chocolate_love",
          "powerCatalog": {
              "bombs": {
                  "level": 3, <-- EDIT THIS
                  "amount": 0
              },
              "wild_shot": {
                  "level": 3, <--
                  "amount": 0
              },
              ...
          }
          ...
      }
  }

Each "key" (the label) has 2 fields: "level" and "amount". You will want
to edit "level". ("amount" isn't used yet)

All Powers have a level cap of 3, except "multi_multiplier" (Doubler/Tripler)
and "inferno_frog". Don't worry about overleveling them though, as the game
will take care of that for you.

To apply Powers:

- Double click on the games folder
- Double click on the ZumaBlitzRemake folder
- Double click on "runtime.json"
- Scroll down until you're inside your profile:

  "selected": "YourName",
  "profiles": {
      "YourName": {
          ...
          "foodInventory": [],
          "equippedPowers": [ "power_1", "power_2", "power_3" ], <-- ADD IT HERE
                                                                     MAKE SURE IT HAS A COMMA
                                                                     AFTER THAT
          "levels" {
              ...
          }
          ...
      }
  }

This takes an array of 0-3 strings (text). Make sure each entry is encapsulated
in quotation marks - and they are completely facing down "" quotation marks
and NOT curly ones such as these: “” or else the game won't read it and potentially
crash. Every entry must have a comma after them except the last one.

Each string must be a valid powerup (seen in powerCatalog). For example:
"equippedPowers": [ "multi_multiplier", "sands_of_time", "fruit_master" ]

This equips Doubler/Tripler, Sands of Time and Fruit Master.

==========

If you want to run the game from it's source code and contribute, check out the GitHub repository:
https://github.com/ZumaBlitzRemake/ZumaBlitzRemake/

Want discussion & updates? Join the Sphere Matchers Discord server:
https://discord.gg/gJgy5x5

==========

Credits:

Project Leads:
- jakubg1 - OpenSMCE developer, lead programmer
  - GitHub: https://github.com/jakubg1
  - Discord: jakubg1#2036
- Shambles_SM - Sub programmer
  - GitHub: https://github.com/ShamblesSM
  - Twitter: https://twitter.com/shambles_sm
  - Discord: Shambles#3117

Contributors:
- Brendan Chan - Zuma Blitz SWF file contribution
  - GitHub: https://github.com/bchantech
  - Discord: bchan#9445
- Cat Warrior - Asset contributions
  - GitHub: https://github.com/CatWarriorOfficial
  - Discord: Cta warrior#4126
- Nagi - Asset contributions
  - GitHub: https://github.com/Nxgi
  - Discord: nagi#1547
- FREN-ZC - Asset fixes
  - GitHub: https://github.com/FREN-ZC
  - Discord: FREN-Z\C#7664
- Tacos - Sound ripping from videos
  - Discord: Tacos#8810
- Glows Lythos - Board backgrounds
  - GitHub: https://github.com/glowslythos
  - Discord: glowslythos#000
- Oreztov - Wild Ball 3d cube recreation
  - GitHub: https://github.com/Oreztov
  - Discord: Oreztov#2411

==========

"Zuma Blitz Remake" is an unofficial fan project and
is not endorsed by or affiliated with EA or PopCap Games.
Any assets used in this fan project belong to their respective owners.

Under no circumstances should this be redistributed for profit.
"Zuma" is a trademark of PopCap Games, a subsidiary of Electronic Arts.

THE AUTHORS OF THIS FAN PROJECT ARE NOT AFFILIATED
WITH EA OR POPCAP GAMES IN ANY WAY. THE AUTHORS
ALSO GAIN NO PROFIT FROM THIS PROJECT WHATSOEVER.
# SUPER STAR TREK MEETS 25TH ANNIVERSARY

## GAME MAKER STUDIO PORT

<p align="center">
  <img src="https://github.com/user-attachments/assets/2669d4e5-73b5-48c4-97c9-590a13fbe707" alt="Screenshot" />
</p>

This game is a free open source port of [Super Star Trek Meets 25th Anniversary](https://emabolo.itch.io/super-star-trek-25th) by Emabolo.

Originally designed with Adventure Game Studio, this Game Maker Studio conversion aims to be both true to the original and open for modularity.

This game is a NON PROFIT Fan Game produced for entertainment purpose only.

All Characters, all related marks, logos and associated names and reference are copyright and trademark of their respective holders.

The content of this Fan Game should not be sold, rented or used for any commercial enterprise in any way, shape or form.

## HOW TO PLAY

You are Captain Kirk! Your mission is to destroy all enemies invading Federation space before time runs out, and don't die trying.

- Use Long Range Sensors to try to detect enemy activity. Sensors will return a count of Enemies, Starbases, and Stars in a 3x3 grid surrounding your ship in the format EBS.
- Warp to sectors with enemies and confront them! Raise shields to protect yourself, then use torpedoes or phasers to fight. Fighting uses energy.
- If running low on energy, seek out a Starbase and contact them. Use Impulse Drive to move next to the base and replenish your energy and repair your ship.
- You have a limited number of days to complete your mission! Changing sectors with Warp Drive uses one day, but will also slowly repair your ship. Plan your moves carefully!
- If the game is too easy, choose from four difficulty modes in the Options menu. You must start a new game for difficulty to take effect.
- The game will autosave whenever you change sectors.
- If you destroy all enemies, you win! But if you are destroyed, become stranded, or run out of time, you lose! Mister Spock can give you updated mission reports.

## HOW TO CONTRIBUTE

This port was designed with modularity in mind. The easiest way to contribute translations is to take a look at the "lang/en.json" file and translate the dialog from that. Name your new file after the proper ISO 639-1 language code and add it to the "langs" folder.

If it's valid JSON, it will appear in the languages selector in the Options menu.

Since this port is open source (search https://github.com/JeodC for the repository), you may submit contributions via Issues or Pull Requests.

## CHANGES

I attempted to keep as close to the original AGS game as possible with formulas. If any game mechanics feel off or are missing, please submit an Issue to the GitHub repository. The following changes were intentionally made:

- Native gamepad support added
- Enhanced graphic effects added (some additional animations, effects applied during red alert)
- Klingons in text changed to Enemies for future support of additional enemy types

Potential ideas:

- I would really love to have an option to select different eras, perhaps beginning with The Next Generation. I am unaware of any similar pixel art however, and lack voice lines.
- Custom scenarios could allow for enemies to explicitly seek out Starbases (a sort of "enhanced" game mode) where you as the player are forced to play defense as well as offense.

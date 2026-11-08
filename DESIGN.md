# DESIGN

School project. First-person psychological horror game about addiction, PS1 style. Godot 4.

## GENERAL
- First-person psychological horror game about addiction, PS1 style.
- All in-game text, menus and UI in English.
- Use the Compatibility renderer so it runs on Mac. Must export to macOS and Web.
- Keep ALL numbers (resolution, fog, timers, rates, countdown, stamina, points) in one config file.
- Tone: serious and human, never glamorising. Drugs are stylised pills, no realistic drug-use imagery.

## VISUAL STYLE
- Internal resolution 640x480 scaled up, nearest texture filter: pixels visible but subtle.
- PSX shader with light vertex jitter and affine texture warping.
- Settings menu: toggle screen shake, volume slider for loud sounds (accessibility).

## PLAYER
- WASD + mouse look, flashlight on F.
- Sprint on Shift with a stamina bar. Withdrawal lowers max stamina.
- First-person body: looking down shows your body and legs; arms and hands visible and swaying when walking. Placeholder boxes now, built so we can swap in Mixamo models from assets/characters later.

## STORY
- The player and his wife lost their daughter in a car crash where he was driving. He has repressed it. His wife is all he has left, and he wants to get clean for her.
- He believes he has been in the recovery center for a few weeks. In reality years have passed, and his wife has moved on with someone else.
- Hints around the hospital: calendars showing different years, staff saying "welcome back", unanswered letters from the wife that get shorter and colder, the mirror reflection looks older each time he wakes up, patients who recognise him.

## CUTSCENES (simple in-engine scenes, same PS1 look)
- Cutscene 1: driving a car, looking back at the daughter in the back seat, laughing together. The wife in the passenger seat suddenly screams. Cut to black.
- Cutscene 2: lying on the street in Philadelphia, deep in addiction.
- Cutscene 3: standing at the daughter's gravestone.
- Cutscenes 1-3 play as flashbacks during withdrawal episodes, in story order.
- Final cutscene A (good ending): the wife visits, but only to say goodbye; she has met someone else. Then he stands alone at the daughter's grave, clean.
- Final cutscene B (game over): "She came. You weren't ready. She left."

## LEVEL 1: OPENING - DOWNTOWN PHILADELPHIA AT DAWN
- Start at a bus stop, walk a few blocks to the recovery center entrance (teaches movement and flashlight).
- Red brick buildings with fire escapes, tall office towers in the background fading into haze, an elevated train on pillars over the street, steam from manholes, parked cars.
- Low sun behind dense orange-amber fog; you see only 1-2 blocks. Streetlights and car headlights still on.
- Sounds (placeholders): distant traffic, far-off siren, train rumbling overhead.
- One pill bottle on the sidewalk: the first temptation.
- One short hallucination: a figure in the fog that vanishes when you approach.
- Entering the front door loads the hospital.

## LEVEL 2: THE RECOVERY CENTER (HOSPITAL)
- Clean white walls, linoleum floors, fluorescent lights, hospital beds, IV stands, wheelchairs, reception desk, English signs.
- Areas: player's room (bed, mirror, clipboard), hallways, common room, doctor's office, group therapy room, courtyard with basketball hoop, lawn with football goal, swimming pool, exit with a doctor.
- NPCs: doctors, nurses and patients walking simple routes or standing. Non-hostile. Placeholders for now.
- A daily schedule board in the hallway shows which activities are open.

## CORE RULES
- Withdrawal meter rises over time without drugs.
- Withdrawal episode: headache effect (pulsing vignette, blur), camera shake, the character grabs his head, shakes it and falls to his knees (brief loss of control), then a flashback plays.
- At high withdrawal, hallucinations appear: screen shakes, a loud sound, and a monster chases the player.
- Taking drugs: hallucinations stop for a while, but items become harder to find (they flicker, blur, fake copies appear), and Recovery drops a lot.
- Finding items lowers withdrawal. Items: 5 personal items (drawing, photo, teddy bear, bracelet, wedding ring) plus the wife's letters.
- If the monster catches you: you wake up in your bed the next morning, back at the start of the hospital.
- Countdown = days until the wife visits. She promised to come if he is clean. Each time you are caught, or forced back to bed, one day passes. At 0: game over (final cutscene B).

## RECOVERY METER (0-100)
Decides when the doctors let you leave. Shown subtly on the clipboard in your room, not as a big bar on screen.
- Gains: time without drugs, surviving a withdrawal episode without using (big gain), finding items and letters, talking to staff (short dialogues with a doctor, a nurse and group therapy where the player picks answers), seeing each flashback, doing activities.
- Losses: taking drugs (big loss).
- Can't pass 90 until all flashbacks have been seen (accepting the truth).
- Exit door: a doctor stops you. Lines depend on the meter: "You're not ready." / "Not yet. You're getting closer." / at 100: "You're ready." and final cutscene A starts.
- Trying to force your way out before 100: you're taken back to bed and lose one day.

## ACTIVITIES (simple minigames, once per in-game day each)
Each gives Recovery and lowers withdrawal. Showing up always gives a little; doing well gives more. Not allowed under the influence ("Come back when you're clean."). At high withdrawal a hallucination can appear during the activity.
- Basketball (courtyard): free throws. Hold mouse to charge, release at the right moment. Withdrawal makes the aim shake.
- Football (lawn): penalty kicks against a patient goalkeeper. Aim with mouse, choose power.
- Swimming (pool): alternate left/right keys in rhythm to swim laps. Losing rhythm makes you sink a little.
- Other patients join and comment ("Nice shot!", "Good to see you here").

## BUILD ORDER (stop after each step)
1. Project setup, player movement, sprint, flashlight, first-person body, visual style, settings menu.
2. Level 1: Philadelphia opening scene.
3. Level 2: hospital layout, NPCs, player room with bed, mirror and clipboard.
4. Withdrawal meter, withdrawal episode, one hallucination monster, drugs.
5. Items, letters, Recovery meter, countdown, exit doctor, waking up in bed.
6. Cutscenes 1-3 as flashbacks.
7. Staff dialogues and group therapy.
8. Activities: basketball, then football, then swimming.
9. Time-passing hints (calendars, mirror, letters, staff lines).
10. Endings (final cutscenes A and B), main menu, export to macOS and Web.

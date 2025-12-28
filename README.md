## S-cíanter Confrontation Builder: System Operational Guide

This guide outlines how the **S-cíanter Confrontation Builder** works (S-cíanter is the translation of "Confrontation" in Bolognese dialect). It is a management platform designed to create customized game profiles and compose valid army lists. The system is managed through a control panel (RailsAdmin) that allows for the manipulation of complex data, dynamic rules, and automatic validations without writing code.

---

### 1. Conceptual Architecture

To use the system correctly, it is fundamental to understand the distinction between **Static Data** (the rulebook) and **Dynamic Data** (your creations).

#### A. The Models (Blueprints)

These data represent the fixed rules of the game. They are usually entered by administrators and do not change often.

* **Fighter:** The base model card (e.g., "Griffin Fusilier"). It contains the base statistics printed on the card.
* **Equipment:** Standard weapons, armor, and items (e.g., "Sword", "Bow").
* **Artifacts:** Unique magical items with special costs and powers.
* **Game Format:** The rules for list construction (e.g., "400 Points", "Ragnarok Tournament").

#### B. The Instances (User Data)

These are the data created by users to play.

* **Profile:** A specific, playable version of a Fighter (e.g., "My Veteran Fusilier with Potion"). A user can have multiple profiles based on the same Fighter.
* **Army List:** A container that groups different Profiles and Nexuses for a specific game, validated according to a Game Format.

---

### 2. The Logic Engine: Modifiers and Requirements

The heart of the system is a dynamic engine that calculates final statistics in real-time. We will never manually enter the final "Strength" value of a modified model; the system will calculate it by summing the various **Stat Modifiers**.

#### How Modifiers Work (StatModifier)

Every bonus or penalty in the game is represented by a `StatModifier` object. This object states:

* **Who gives it (Source):** An Affiliation, a Weapon, a Spell.
* **What it modifies (Definition):** Strength, Attack, Cost, Ability.
* **How it modifies it (Type):**
* `SET`: Sets the value to X (overwrites everything).
* `ADD`: Adds X to the base value.
* `SUB`: Subtracts X.


* **Condition:** If the bonus applies only in certain cases (e.g., "While charging").

> **Example in RailsAdmin:** If you create a "Long Sword", you will create a `StatModifier` associated with it that has `Definition: Strength`, `Type: ADD`, `Value: 2`.

#### The Guardian: Requirements (Requirement)

To prevent illegal combinations (e.g., a mage using heavy armor), the system uses `Requirements`. A requirement can be linked to any object (Artifact, Ability, Equipment) to limit its use.

Types of checks performed:

1. **Entity Check:** "Must be a Wolfen", "Must belong to the Army of the Lion".
2. **Stat Check:** "Must have Strength > 5", "Cost must be < 50".

---

### 3. Creation Guide: Content Management (Admin)

In this phase, the administrator populates the database with game elements via RailsAdmin.

#### Creating a Fighter

In the **Fighters** panel:

1. Enter **Name**, **Rank**, **Size**, and **Base Cost**.
2. Fill in the **Base Statistics** (Movement, Attack, etc.).
3. **Default Equipment:** Select the standard equipment the model has "stock" (e.g., Sword and Shield). This will be automatically copied to every new profile created from this fighter.

#### Creating Equipment and Artifacts

In the **Equipment** or **Artifacts** panel:

1. Create the item (e.g., "Great Axe").
2. **Stat Modifiers (Nested Form):** Here you define what the item does. Add a new row:
* *Stat Definition:* "Strength"
* *Modification Type:* "ADD"
* *Value:* 2


3. **Requirements (Nested Form):** Here you define who can use it.
* *Check Type:* Stat
* *Stat Code:* "Strength"
* *Min Value:* 4
* *(Result: Only those with Strength 4 or higher can equip this axe).*



---

### 4. User Guide: Creating a Playable Profile (User)

This is the phase where a user creates their virtual "soldiers" ready to be included in a list.

#### Step 1: Creating the Base Profile

Go to **Profiles** and click on **Add New**.

1. **User:** Select the owner user.
2. **Fighter:** Select the base model (e.g., "Kassar").
3. **Custom Name:** (Optional) Give a unique name, e.g., "Kassar the Fugitive".
4. **Affiliation:** Choose an affiliation (e.g., "The Eclipse").
* *Note:* Upon saving, the system checks if the chosen Affiliation grants mandatory bonuses. If so, it automatically creates the necessary modifiers on the profile.


5. **Save:** Once saved, the profile automatically inherits the base **Equipment** of the Fighter.

#### Step 2: Customization (Modifiers and Equipment)

Once the profile is created, you can modify it:

* **Equipment Management:**
* You can remove base equipment.
* You can add new equipment from the list.
* *Validity Check:* If you try to add an item whose `Requirements` are not met by the Fighter (e.g., insufficient Strength), the system might block the addition or flag the error.


* **Adding Artifacts:**
* Similar to equipment, but you select from **Artifacts**.
* The system checks if the Fighter is "Worthy" (Requirements) of the artifact.



#### Step 3: Verifying Statistics

In RailsAdmin, viewing the details of the **Profile**, you will see the calculated statistics. The system has already done the math:



If a modifier was of type `SET`, the base value was overwritten before the sums.

---

### 5. Building an Army List

The final step is to assemble profiles into a fighting force.

#### A. Game Formats (GameFormat)

Before creating a list, a Format must exist (e.g., "Standard 400pt"). This defines the limits the system will use to validate the list:

* Max Points (e.g., 400).
* % Characters (e.g., Max 50%).
* Max Copies of the same profile.

#### B. Creating the List (ArmyList)

Go to **Army Lists** and create a new list:

1. Assign a **Name** and select the reference **Army**.
2. Select the **Game Format**.
3. **Save**.

#### C. Adding Units (List Entries)

In the List screen, manage the **List Entries**:

1. Add a new Entry.
2. Select a **Profile** from your library (created in step 4).
* *Advantage:* Being a reference, if you update the Profile (e.g., change a weapon), the list updates automatically.


3. Set the **Quantity** (e.g., 3 copies of this infantryman).

#### D. Validation and Feedback

Every time you save the list or add a unit, the system performs a complete legality check (`Validate Composition Rules`).
It checks if:

* You have exceeded the max points.
* You have too many characters or war machines.
* You have too many duplicates of the same card.
* You have met the minimum number of models.

If the list is not valid, RailsAdmin will show a specific **validation error** (e.g., *"Excessive Character Points: 250/200"*), preventing you from publishing or finalizing the list until you correct the quantities.

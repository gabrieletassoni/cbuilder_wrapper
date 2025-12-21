# CBuilder: Architettura Rails per Confrontation 5 (C5)

Ecco una proposta completa per un'architettura Ruby on Rails (versione 7+) progettata per gestire la complessità di **Confrontation 5 (C5)**.

Il progetto è diviso in tre parti:

1. **Struttura del Database (ERD)**
2. **Comandi Generatori e Migrazioni**
3. **File di Seeding (Popolamento Dati)** con i dati estratti dai PDF forniti (Daikinee, Divoratori, Magie, Miracoli).

---

### Parte 1: Struttura del Database (Logica)

Per gestire la complessità di C5 (profili base, affiliazioni che modificano statistiche, costi variabili, magie legate a vie specifiche), useremo una struttura relazionale.

* **Armies**: I popoli (es. Elfi Daikinee, Divoratori).
* **Affiliations**: Le sotto-fazioni (es. Armata di Laureken, L'Eclisse).
* **Fighters**: I profili dei modelli. Qui salveremo sia i profili "Base" che quelli "Modificati" (come richiesto).
* **Stats**: Una tabella polimorfica o colonne dirette in Fighter per gestire le caratteristiche (MOV, INI, ATT, etc.). *Per semplicità in Rails, useremo colonne dirette nel modello Fighter.*
* **Skills**: Le abilità speciali (es. Rigenerazione, Autorità).
* **FighterSkills**: Tabella di unione che gestisce il valore "X" dell'abilità (es. Rigenerazione **5**).
* **Spells / Miracles**: Tabelle per le arti mistiche.
* **Artifacts / Equipment**: Oggetti magici ed equipaggiamento mondano.

---

### Parte 2: Generatori e Migrazioni

Esegui questi comandi nel terminale della tua applicazione Rails.

```bash
# 1. Core Strutturale
rails g model Army name:string description:text
rails g model Affiliation name:string army:references bonus_description:text

# 2. Modello Combattente (Fighter)
# Include tutte le statistiche. 'is_unique' per i personaggi, 'base_cost' per i punti armata.
rails g model Fighter name:string title:string army:references affiliation:references \
rank:string base_cost:integer size:string \
mov_ground:float mov_fly:float ini:integer att:integer for_str:integer dif:integer res:integer \
tir:integer courage:integer fear:integer discipline:integer \
power:integer faith_create:integer faith_alter:integer faith_destroy:integer \
is_character:boolean is_base_profile:boolean

# 3. Abilità e Relazioni
rails g model Skill name:string description:text has_value:boolean
rails g model FighterSkill fighter:references skill:references value:integer

# 4. Magia e Fede
rails g model MagicPath name:string element:string # Es. "Ctonia", "Fuoco"
rails g model Spell name:string magic_path:references difficulty:string cost_string:string \
range:string duration:string effect:text frequency:string

rails g model Deity name:string # Es. "Yllia", "Vile-Tis"
rails g model Miracle name:string deity:references aspects:string fervor:string \
difficulty:string range:string duration:string effect:text

# 5. Equipaggiamento e Artefatti
rails g model Artifact name:string description:text cost:integer is_relic:boolean army:references
rails g model Nexus name:string resistance:integer structure:integer cost:integer effect:text army:references

# 6. Tabelle di unione per "Cosa sa lanciare questo modello?"
rails g migration CreateJoinTableFightersSpells fighter spell
rails g migration CreateJoinTableFightersMiracles fighter miracle

```

#### Modifica delle Migrazioni

Prima di eseguire `rails db:migrate`, assicurati che le tabelle siano corrette. Ecco una nota importante per i campi che possono essere `NULL` (es. un guerriero non ha POTere).

*Aggiungi `null: true` o `default: nil` nelle migrazioni per le statistiche che possono non esistere (TIR, POT, FEDE).*

```ruby
# Esempio parziale dentro db/migrate/[timestamp]_create_fighters.rb
t.integer :tir, allow_nil: true
t.integer :power, allow_nil: true # POT
t.integer :faith_create, allow_nil: true
# ...

```

---

### Parte 3: I Modelli (app/models/...)

Configura le relazioni chiave.

```ruby
# app/models/fighter.rb
class Fighter < ApplicationRecord
  belongs_to :army
  belongs_to :affiliation, optional: true
  has_many :fighter_skills
  has_many :skills, through: :fighter_skills
  has_and_belongs_to_many :spells
  has_and_belongs_to_many :miracles
  
  # Enum per i ranghi per facilitare la gestione
  enum rank: { irregolare: 0, regolare: 1, veterano: 2, creatura: 3, speciale: 4, elite: 5, leggenda: 6 }
end

# app/models/fighter_skill.rb
class FighterSkill < ApplicationRecord
  belongs_to :fighter
  belongs_to :skill
  # Il campo 'value' conterrà il valore X (es. 5 per Rigenerazione/5)
end

```

---

### Parte 4: File di Seeding (db/seeds.rb)

Questo è il cuore della richiesta. Basandomi sui PDF forniti, ecco come popolare il database. Ho estratto i dati per creare le abilità, le magie e due fazioni complete (Daikinee e Divoratori) con esempi di profili modificati dalle affiliazioni.

```ruby
# db/seeds.rb

puts "Cancellazione DB esistente..."
Fighter.destroy_all
Skill.destroy_all
Spell.destroy_all
Miracle.destroy_all
Affiliation.destroy_all
Army.destroy_all
MagicPath.destroy_all
Deity.destroy_all

puts "--- Creazione Abilità Globali (Esempi) ---"
skills_data = [
  { name: "Rigenerazione", has_value: true },
  { name: "Tossico", has_value: true },
  { name: "Comando", has_value: true },
  { name: "Immutabilità/Paura", has_value: false },
  { name: "Uccisore Nato", has_value: false },
  { name: "Posseduto", has_value: false },
  { name: "Esploratore", has_value: false },
  { name: "Accanito", has_value: false },
  { name: "Furia Guerriera", has_value: false },
  { name: "Sequenza di Colpi", has_value: true },
  { name: "Colpo da Maestro", has_value: true }
]
skills = {}
skills_data.each do |s|
  skills[s[:name]] = Skill.create!(s)
end

puts "--- Creazione Vie di Magia ---"
paths = {
  "Primagia" => MagicPath.create!(name: "Primagia", element: "Neutro"),
  "Necromanzia" => MagicPath.create!(name: "Necromanzia", element: "Tenebra"),
  "Ctonia" => MagicPath.create!(name: "Ctonia", element: "Terra"),
  "Fatata" => MagicPath.create!(name: "Fatata", element: "Acqua"),
  "Ululati" => MagicPath.create!(name: "Ululati", element: "Acqua/Tenebra") # Tipico dei Divoratori
}

puts "--- Popolamento Magie (Estratto da File 2) ---"
Spell.create!([
  { name: "Presentimento", magic_path: paths["Primagia"], difficulty: "5", cost_string: "1 Neutra", range: "Speciale", duration: "Istantanea", effect: "Guarda la prima carta avversaria." },
  { name: "Palla di Fuoco", magic_path: paths["Primagia"], difficulty: "9", cost_string: "2 Fuoco", range: "25 cm", duration: "Istantanea", effect: "Tiro a FOR 8, Artiglieria Leggera a Zona." },
  { name: "Necrosi", magic_path: paths["Biopsia"], difficulty: "Libera", cost_string: "2 Tenebre", range: "Contatto", duration: "Istantanea", effect: "Test RES vs Difficoltà+3 o subisce ferita." },
  # Aggiungere qui altre magie dal PDF 2
])

puts "--- Creazione Divinità e Miracoli (Estratto da File 3) ---"
deities = {
  "Universale" => Deity.create!(name: "Universale"),
  "Vile-Tis" => Deity.create!(name: "Vile-Tis"), # Divoratori
  "Earthë" => Deity.create!(name: "Earthë")      # Daikinee
}

Miracle.create!([
  { name: "Aura d'Ardimento", deity: deities["Universale"], aspects: "0-1-0", fervor: "1", difficulty: "6", range: "Personale", effect: "Recupera rotta e +1 COR a portata." },
  { name: "Artiglio del Demone", deity: deities["Vile-Tis"], aspects: "0-0-1", fervor: "2", difficulty: "Somma Aspetti +3", range: "20 cm", effect: "Tiro per ferire forza pari a F.T. attuale." },
  { name: "Occhio di Earthè", deity: deities["Earthë"], aspects: "0-1-0", fervor: "1", difficulty: "Somma Aspetti +3", range: "50 cm", effect: "Il bersaglio acquisisce Prevedibile." }
])

puts "--- Creazione Armate e Affiliazioni ---"

# 1. DAIKINEE (Dati da File 9)
daikinee = Army.create!(name: "Elfi Daikinee", description: "Elfi antichi legati alla natura e alle fate.")

daikinee_affs = {
  "Laureken" => Affiliation.create!(name: "Armata di Laureken", army: daikinee, bonus_description: "Regolari/Veterani 4 per carta senza costo. Alleati Aquila 25%. Solo Reali."),
  "Nuham" => Affiliation.create!(name: "Nuham", army: daikinee, bonus_description: "Maneos ottiene Comando/10. Cittadella: Strenui Difensori (ritardo morte)."),
  "Laronn" => Affiliation.create!(name: "Difensori di Laronn", army: daikinee, bonus_description: "Segnalini Simbiosi. Alleati Wolfen Yllia."),
  "Indatte" => Affiliation.create!(name: "Indatte", army: daikinee, bonus_description: "Mercenari 35%. Generale deve essere Daikinee."),
  "Base" => nil # Per profili generici
}

# 2. DIVORATORI (Dati da File 11)
devourers = Army.create!(name: "Divoratori di Vile-Tis", description: "Wolfen corrotti dalla Bestia.")

devourers_affs = {
  "Eclisse" => Affiliation.create!(name: "L'Eclisse", army: devourers, bonus_description: "Flagello contro bersaglio designato."),
  "Massacro" => Affiliation.create!(name: "Il Massacro", army: devourers, bonus_description: "+1 COR/PAU. Disingaggio automatico da Rotta."),
  "Armageddon" => Affiliation.create!(name: "L'Armageddon", army: devourers, bonus_description: "+1 DIS. Autorità a rotazione."),
  "Base" => nil
}

puts "--- Creazione Profili Combattenti (Truppa & Personaggi) ---"

# --- ELFI DAIKINEE ---
# Base Profiles
archer = Fighter.create!(
  name: "Arciere Daikinee",
  title: "Truppa Regolare",
  army: daikinee,
  rank: "regolare",
  base_cost: 11,
  size: "Media",
  mov_ground: 12.5, ini: 3, att: 2, for_str: 3, dif: 2, res: 5, tir: 3,
  discipline: 3,
  is_character: false,
  is_base_profile: true
)
FighterSkill.create!(fighter: archer, skill: skills["Rigenerazione"], value: 5)

guardian = Fighter.create!(
  name: "Guardiano Daikinee (Spada)",
  title: "Truppa Veterana",
  army: daikinee,
  rank: "veterano",
  base_cost: 15,
  size: "Media",
  mov_ground: 12.5, ini: 3, att: 3, for_str: 5, dif: 4, res: 6,
  discipline: 4,
  is_character: false,
  is_base_profile: true
)
FighterSkill.create!(fighter: guardian, skill: skills["Esploratore"])
FighterSkill.create!(fighter: guardian, skill: skills["Rigenerazione"], value: 5)

# Character: Numae
numae = Fighter.create!(
  name: "Numae",
  title: "Guardiano Daikinee",
  army: daikinee,
  rank: "regolare", # Personaggio su base regolare
  base_cost: 41,
  size: "Media",
  mov_ground: 12.5, ini: 4, att: 5, for_str: 6, dif: 7, res: 5,
  courage: 4, discipline: 3,
  is_character: true,
  is_base_profile: true
)
FighterSkill.create!(fighter: numae, skill: skills["Comando"], value: 10)
FighterSkill.create!(fighter: numae, skill: skills["Rigenerazione"], value: 5)

# --- PROFILI MODIFICATI DAIKINEE (Esempio Nuham) ---
# In Nuham, Maneos ottiene Comando/10 se affiliato.
maneos_nuham = Fighter.create!(
  name: "Maneos (Nuham)",
  title: "Guardiano di Nuham",
  army: daikinee,
  affiliation: daikinee_affs["Nuham"],
  rank: "elite",
  base_cost: 70, # Costo base + eventuali costi affiliazione se applicabili
  size: "Media",
  mov_ground: 12.5, ini: 5, att: 6, for_str: 7, dif: 10, res: 5,
  courage: 6, discipline: 3,
  is_character: true,
  is_base_profile: false # Questo è un profilo modificato
)
FighterSkill.create!(fighter: maneos_nuham, skill: skills["Comando"], value: 10) # Bonus affiliazione
FighterSkill.create!(fighter: maneos_nuham, skill: skills["Colpo da Maestro"], value: 2)
FighterSkill.create!(fighter: maneos_nuham, skill: skills["Rigenerazione"], value: 5)


# --- DIVORATORI DI VILE-TIS ---
# Base Profiles
warrior_blood = Fighter.create!(
  name: "Guerriero del Sangue",
  title: "Truppa Regolare",
  army: devourers,
  rank: "regolare",
  base_cost: 16,
  size: "Media",
  mov_ground: 12.5, ini: 3, att: 4, for_str: 5, dif: 4, res: 7,
  courage: 1, discipline: 4,
  is_character: false,
  is_base_profile: true
)
FighterSkill.create!(fighter: warrior_blood, skill: skills["Ambidestro"])

half_elf_hunter = Fighter.create!(
  name: "Cacciatore di Teste",
  title: "Truppa Regolare",
  army: devourers,
  rank: "regolare",
  base_cost: 26,
  size: "Media",
  mov_ground: 17.5, ini: 4, att: 4, for_str: 5, dif: 4, res: 7,
  fear: 5, discipline: 3,
  is_character: false,
  is_base_profile: true
)
FighterSkill.create!(fighter: half_elf_hunter, skill: skills["Uccisore Nato"])

# Character: Kassar
kassar = Fighter.create!(
  name: "Kassar il Fuggitivo",
  title: "Eterno Fuggitivo",
  army: devourers,
  rank: "irregolare",
  base_cost: 62,
  size: "Grande", # Wolfen
  mov_ground: 17.5, ini: 6, att: 6, for_str: 10, dif: 4, res: 7,
  fear: 6, discipline: 1,
  is_character: true,
  is_base_profile: true
)
FighterSkill.create!(fighter: kassar, skill: skills["Esploratore"])
FighterSkill.create!(fighter: kassar, skill: skills["Uccisore Nato"])

# --- PROFILI MODIFICATI DIVORATORI (Esempio Massacro) ---
# Il Massacro: +1 COR/PAU
warrior_blood_massacre = Fighter.create!(
  name: "Guerriero del Sangue (Massacro)",
  title: "Vandalo del Massacro",
  army: devourers,
  affiliation: devourers_affs["Massacro"],
  rank: "regolare",
  base_cost: 16 + 1, # Costo base + 1 pa costo affiliazione Rango 1
  size: "Media",
  mov_ground: 12.5, ini: 3, att: 4, for_str: 5, dif: 4, res: 7,
  courage: 2, # +1 dal bonus affiliazione (era 1)
  discipline: 4,
  is_character: false,
  is_base_profile: false
)
FighterSkill.create!(fighter: warrior_blood_massacre, skill: skills["Ambidestro"])

puts "--- Creazione Artefatti e Nexus (Esempi) ---"

# Daikinee Artifacts
Artifact.create!(name: "L'Arco Spirito", cost: 10, army: daikinee, description: "Riservato a Kurujai. Arma Simbiotica. Dona Maestro Arciere. Forza 6/25-45-65. Genera mana uccidendo.")
Artifact.create!(name: "Elmo del Silenzio", cost: 7, army: daikinee, description: "Riservato a Kishdan. Esploratore in volo se nessun nemico a 10cm. Comando esteso a livelli adiacenti.")

# Daikinee Nexus
Nexus.create!(name: "Ucorno", army: daikinee, cost: 10, resistance: 8, structure: 5, effect: "Alleanza Scarabeo. Difficoltà 7 per Fate/Fedeli. Fornisce Vigore. Può Trascinarsi, Bloccare o Colpire.")

# Devourers Artifacts
Artifact.create!(name: "Daga di Ossidiana", cost: 6, army: devourers, description: "Riservato a Kassar. Conferisce l'abilità Assassino.")
Artifact.create!(name: "Maschera della Ferocia", cost: 10, army: devourers, description: "Riservato a Nekhar. Conferisce Accanito e Furia Guerriera. Vincolo dadi attacco/difesa.")

puts "Seeding completato con successo!"

```

### Istruzioni per l'uso

1. Crea una nuova app Rails: `rails new confrontation_builder --database=postgresql` (Consigliato Postgres per jsonb e future scalabilità, ma sqlite va bene per iniziare).
2. Esegui i comandi dei generatori riportati nella Parte 2.
3. Copia il codice dei modelli nella cartella `app/models`.
4. Copia il codice di seeding in `db/seeds.rb`.
5. Esegui `rails db:migrate` e poi `rails db:seed`.

Questa struttura permette di:

* Cercare unità per armata.
* Filtrare per affiliazione.
* Vedere automaticamente le statistiche modificate se si seleziona il profilo "affiliato".
* Gestire le liste di incantesimi e miracoli disponibili.
* Gestire equipaggiamenti complessi tramite descrizioni testuali o espandendo il modello `Artifact` se necessario.

Certamente. È un'ottima idea normalizzare ulteriormente il database. In *Confrontation 5*, i Ranghi hanno valori specifici (es. Regolare = 1, Adepto = 2) e le Taglie determinano direttamente le ferite e la possanza base. Creare tabelle dedicate renderà l'applicazione molto più robusta e facile da aggiornare.

Ecco la struttura aggiornata e i nuovi comandi.

### 1. Nuova Struttura del Database (Modifiche)

* **Tabella `ranks**`: Sostituisce l'enum. Contiene il nome (es. "Veterano", "Iniziato") e il valore in termini di regole (es. 1, 2).
* 
**Tabella `sizes**`: Contiene la definizione della Taglia (es. "Media", "Grande"), le **ferite base** associate, la **possanza** (che dipende dalla taglia ) e la descrizione del **tipo di basetta** standard per quella taglia.


* **Tabella `fighters**`: Ora ha chiavi esterne (`rank_id`, `size_id`) invece di colonne stringa/integer dirette per questi dati.

---

### 2. Comandi Generatori e Migrazioni

Esegui questi comandi nel terminale Rails (in ordine):

```bash
# 1. Crea i nuovi modelli di supporto
rails g model Rank name:string value:integer
rails g model Size name:string base_wounds:integer base_power:integer base_dimensions:string

# 2. (Opzionale) Se hai già creato i modelli precedenti, crea una migrazione per modificarli:
# rails g migration ChangeFighterStructure

# OPPURE, se stai ripartendo da zero, usa questo comando aggiornato per Fighter:
rails g model Fighter name:string title:string \
  army:references affiliation:references \
  rank:references size:references \
  base_cost:integer \
  mov_ground:float mov_fly:float ini:integer att:integer for_str:integer dif:integer res:integer \
  tir:integer courage:integer fear:integer discipline:integer \
  faith_create:integer faith_alter:integer faith_destroy:integer \
  is_character:boolean is_base_profile:boolean

# 3. Le altre tabelle rimangono invariate (riporto per completezza)
rails g model Army name:string description:text
rails g model Affiliation name:string army:references bonus_description:text
rails g model Skill name:string description:text has_value:boolean
rails g model FighterSkill fighter:references skill:references value:integer
rails g model MagicPath name:string element:string
rails g model Spell name:string magic_path:references difficulty:string cost_string:string range:string duration:string effect:text
rails g model Deity name:string
rails g model Miracle name:string deity:references aspects:string fervor:string difficulty:string range:string duration:string effect:text
rails g model Artifact name:string description:text cost:integer is_relic:boolean army:references
rails g model Nexus name:string resistance:integer structure:integer cost:integer effect:text army:references

# 4. Tabelle di unione
rails g migration CreateJoinTableFightersSpells fighter spell
rails g migration CreateJoinTableFightersMiracles fighter miracle

```

---

### 3. Modelli Aggiornati

Ecco come aggiornare le relazioni nei file `app/models/`.

```ruby
# app/models/rank.rb
class Rank < ApplicationRecord
  has_many :fighters
  validates :name, presence: true
  validates :value, presence: true
end

# app/models/size.rb
class Size < ApplicationRecord
  has_many :fighters
  validates :base_wounds, presence: true
  # [cite_start]Possanza è legata alla taglia nel regolamento (es. Piccola=1, Grande=2) [cite: 7650]
end

# app/models/fighter.rb
class Fighter < ApplicationRecord
  belongs_to :army
  belongs_to :affiliation, optional: true
  belongs_to :rank  # Nuova associazione
  belongs_to :size  # Nuova associazione
  
  has_many :fighter_skills
  has_many :skills, through: :fighter_skills
  has_and_belongs_to_many :spells
  has_and_belongs_to_many :miracles
end

```

---

### 4. File di Seeding (db/seeds.rb) Aggiornato

Questo file popola le tabelle `Rank` e `Size` secondo le tabelle del regolamento (File 1, pag. 6-7 e pag. 114) e le usa per creare i combattenti.

```ruby
# db/seeds.rb

puts "Pulizia Database..."
[Fighter, Rank, Size, Skill, Army, Affiliation, Spell, Miracle].each(&:destroy_all)

# --- 1. POPOLAMENTO RANGHI (File 1, Fonte 7616-7640) ---
puts "Creazione Ranghi..."
ranks = {
  # Ranghi Guerrieri
  "Irregolare" => Rank.create!(name: "Irregolare", value: 1),
  "Regolare" => Rank.create!(name: "Regolare", value: 1),
  "Veterano" => Rank.create!(name: "Veterano", value: 1),
  "Creatura" => Rank.create!(name: "Creatura", value: 1),
  "Macchina da Guerra" => Rank.create!(name: "Macchina da Guerra", value: 1),
  "Speciale" => Rank.create!(name: "Speciale", value: 2),
  "Elite" => Rank.create!(name: "Elite", value: 2),
  "Leggenda Vivente" => Rank.create!(name: "Leggenda Vivente", value: 3),
  "Alleato Maggiore" => Rank.create!(name: "Alleato Maggiore", value: 4),
  # Ranghi Mistici (Maghi/Fedeli)
  "Iniziato" => Rank.create!(name: "Iniziato", value: 1),
  "Adepto" => Rank.create!(name: "Adepto", value: 2),
  "Maestro" => Rank.create!(name: "Maestro", value: 3),
  "Virtuoso" => Rank.create!(name: "Virtuoso", value: 4),
  "Devoto" => Rank.create!(name: "Devoto", value: 1),
  "Zelota" => Rank.create!(name: "Zelota", value: 2),
  "Decano" => Rank.create!(name: "Decano", value: 3),
  "Avatar" => Rank.create!(name: "Avatar", value: 4)
}

# --- 2. POPOLAMENTO TAGLIE (File 1, Fonte 7650 + 7652) ---
puts "Creazione Taglie..."
# Nota: La tabella a pag. 7 del regolamento definisce il legame Taglia -> Ferite/Possanza
sizes = {
  [cite_start]"Piccola" => Size.create!(name: "Piccola", base_wounds: 4, base_power: 1, base_dimensions: "Fanteria (25x25mm)"), # [cite: 7650]
  [cite_start]"Media" => Size.create!(name: "Media", base_wounds: 4, base_power: 1, base_dimensions: "Fanteria (25x25mm)"),   # [cite: 7650]
  [cite_start]"Grande (Cavalleria)" => Size.create!(name: "Grande (Cavalleria)", base_wounds: 5, base_power: 2, base_dimensions: "Cavalleria (25x50mm)"), # [cite: 7650, 7652]
  [cite_start]"Grande (Creatura)" => Size.create!(name: "Grande (Creatura)", base_wounds: 5, base_power: 2, base_dimensions: "Creatura (37.5x37.5mm)"),   # [cite: 7650, 7652]
  [cite_start]"Enorme" => Size.create!(name: "Enorme", base_wounds: 6, base_power: 3, base_dimensions: "Creatura Grande (50x50mm)"), # [cite: 7650]
  [cite_start]"Molto Grande" => Size.create!(name: "Molto Grande", base_wounds: 7, base_power: 4, base_dimensions: "Speciale"), # [cite: 7650]
  [cite_start]"Gigantesco" => Size.create!(name: "Gigantesco", base_wounds: 8, base_power: 5, base_dimensions: "Speciale")      # [cite: 7650]
}

# --- 3. CREAZIONE ESERCITI & AFFILIAZIONI ---
puts "Creazione Eserciti..."
daikinee = Army.create!(name: "Elfi Daikinee")
devourers = Army.create!(name: "Divoratori di Vile-Tis")

# --- 4. CREAZIONE COMBATTENTI (Esempi) ---

# Esempio: Arciere Daikinee (File 9)
# Rango: Regolare | Taglia: Media (Fanteria)
Fighter.create!(
  name: "Arciere Daikinee",
  title: "Truppa Regolare",
  army: daikinee,
  rank: ranks["Regolare"], # Usa la tabella associata
  size: sizes["Media"],    # Usa la tabella associata (Ferite 4, Possanza 1 automatiche via associazione logicamente, ma qui esplicite nel modello se vuoi)
  base_cost: 11,
  mov_ground: 12.5, ini: 3, att: 2, for_str: 3, dif: 2, res: 5, tir: 3,
  discipline: 3,
  is_character: false,
  is_base_profile: true
)

# Esempio: Kassar il Fuggitivo (File 11)
# Rango: Irregolare | [cite_start]Taglia: Grande (è un Wolfen) [cite: 7644]
# [cite_start]Nota: I Wolfen sono generalmente Taglia Grande [cite: 7644, 7650]
Fighter.create!(
  name: "Kassar il Fuggitivo",
  title: "L'Eterno Fuggitivo",
  army: devourers,
  rank: ranks["Irregolare"],
  size: sizes["Grande (Creatura)"], # Wolfen usano base Creatura o Grande
  base_cost: 62,
  mov_ground: 17.5, ini: 6, att: 6, for_str: 10, dif: 4, res: 7,
  fear: 6, discipline: 1,
  is_character: true,
  is_base_profile: true
)

puts "Seeding completato."

```

Questa struttura ti permette, ad esempio, di fare query come:
`Fighter.joins(:size).where(sizes: { base_wounds: 4 })` per trovare tutti i modelli con 4 ferite base, oppure di cambiare globalmente il valore di un rango se le regole dovessero evolvere, modificando solo la riga nella tabella `ranks`.

Ecco i file CSV strutturati e pronti per l'importazione. Ho creato una struttura relazionale logica: invece di usare ID numerici (che non conosciamo prima dell'importazione), ho usato i **nomi** come chiavi di riferimento (es. `army_name`, `rank_name`) che il tuo script di importazione dovrà cercare nel database.

Ho incluso i profili base e ho creato **esempi specifici di profili modificati dalle affiliazioni** basandomi sulle regole di restrizione e bonus descritte nei documenti.

### 1. `armies.csv`

Definisce le fazioni principali.

```csv
name,description
[cite_start]Elfi Daikinee,"Elfi antichi legati alla natura e alle fate, abitanti di Quitaryan[cite: 12831]."
[cite_start]Divoratori di Vile-Tis,"Wolfen corrotti dalla Bestia, nemici degli dei e di Yllia[cite: 7010]."

```

### 2. `ranks.csv`

Definisce i ranghi secondo il regolamento .

```csv
name,value,type
Irregolare,1,Guerriero
Regolare,1,Guerriero
Veterano,1,Guerriero
Creatura,1,Guerriero
Macchina da Guerra,1,Guerriero
Speciale,2,Guerriero
Elite,2,Guerriero
Leggenda Vivente,3,Guerriero
Alleato Maggiore,4,Guerriero
Iniziato,1,Mistico
Adepto,2,Mistico
Maestro,3,Mistico
Virtuoso,4,Mistico
Devoto,1,Fedele
Zelota,2,Fedele
Decano,3,Fedele
Avatar,4,Fedele

```

### 3. `sizes.csv`

Definisce le taglie e le statistiche base associate.

```csv
name,base_wounds,base_power,base_dimensions
Piccola,4,1,"Fanteria (25x25mm)"
Media,4,1,"Fanteria (25x25mm)"
Grande (Cavalleria),5,2,"Cavalleria (25x50mm)"
Grande (Creatura),5,2,"Creatura (37.5x37.5mm)"
Enorme,6,3,"Creatura Grande (50x50mm)"
Molto Grande,7,4,"Speciale"
Gigantesco,8,5,"Speciale"

```

### 4. `affiliations.csv`

Definisce le sotto-fazioni e i loro bonus generici.

```csv
name,army_name,bonus_description
[cite_start]Armata di Laureken,Elfi Daikinee,"Regolari/Veterani schierabili 4 per carta senza costo affiliazione[cite: 12835]."
Nuham,Elfi Daikinee,"Maneos ottiene Comando/10. [cite_start]Strenui Difensori: ritardo rimozione perdite[cite: 12849]."
Difensori di Laronn,Elfi Daikinee,"Segnalini Simbiosi. [cite_start]Alleati Wolfen Yllia permessi[cite: 12866]."
Anima di Quithayran,Elfi Daikinee,"40% armata deve essere Fata. [cite_start]Fate costo <=25 ottengono Rinforzi[cite: 12883]."
Indatte,Elfi Daikinee,"Mercenari permessi (35%). [cite_start]Generale deve essere Daikinee[cite: 12903]."
[cite_start]L'Eclisse,Divoratori di Vile-Tis,"Flagello contro bersaglio designato dopo Tattica[cite: 7019]."
Il Massacro,Divoratori di Vile-Tis,"+1 COR/PAU. Disingaggio automatico da Rotta. [cite_start]Costo affiliazione pari al Rango[cite: 7033]."
L'Armageddon,Divoratori di Vile-Tis,"+1 DIS. [cite_start]Autorità a rotazione[cite: 7044]."
[cite_start]L'Estasi,Divoratori di Vile-Tis,"Tutti ottengono Posseduto (costo pari al rango)[cite: 7058]."
[cite_start]Il Blasfemo,Divoratori di Vile-Tis,"Segnalini Anatema per rilanciare dadi[cite: 7068]."
L'Impuro,Divoratori di Vile-Tis,"50% Mezzelfi (sconto PA). [cite_start]Solo specifici per Mezzelfi[cite: 7085]."
Dun-Scaith,Divoratori di Vile-Tis,"Alleanza con Druni (40%/40%). No Mezzelfi. [cite_start]Furia Sanguinaria (no disingaggio volontario)[cite: 7131]."

```

### 5. `skills.csv`

Elenco delle abilità comuni e speciali.

```csv
name,has_value,description
[cite_start]Rigenerazione,true,"Recupera ferite con 1d6 >= X in mantenimento[cite: 9696]."
Tossico,true,"Genera dadi tossico. [cite_start]Infligge ferite dirette a FOR X con RES 0[cite: 9796]."
[cite_start]Comando,true,"Trasmette COR e DIS entro X cm[cite: 9406]."
[cite_start]Immunità/Paura,false,"Non effettua test di Coraggio[cite: 9572]."
Uccisore Nato,false,"Dado extra in attacco. [cite_start]Supera auto test COR <= proprio COR[cite: 9813]."
[cite_start]Posseduto,false,"Penalità ferite ridotte di un livello[cite: 9679]."
[cite_start]Esploratore,false,"Schieramento avanzato nascosto[cite: 9472]."
[cite_start]Accanito,false,"Rimosso a fine fase se ucciso[cite: 9319]."
[cite_start]Furia Guerriera,false,"Dado extra in attacco ma obbligo tutti dadi in attacco[cite: 9526]."
[cite_start]Ambidestro,false,"Dado attacco extra per ogni difesa riuscita[cite: 9332]."
[cite_start]Contrattacco,false,"Dado attacco extra per ogni difesa riuscita di 2+[cite: 9430]."
[cite_start]Sequenza di Colpi,true,"Fino a X dadi extra con penalità -1 ATT/DIF[cite: 9739]."
[cite_start]Colpo da Maestro,true,"Sacrifica 2 dadi attacco per 1 colpo a FOR + ATT + X[cite: 9403]."
[cite_start]Artefatto,true,"Può portare X artefatti[cite: 9344]."
[cite_start]Taumaturgo,false,"Aura fede aumenta 5cm per ogni ferita subita[cite: 9755]."

```

### 6. `artifacts.csv`

Artefatti specifici estratti dai file 9 e 11.

```csv
name,cost,army_name,description,is_relic
L'Arco Spirito,10,Elfi Daikinee,"Riservato a Kurujai. Arma Simbiotica. Dona Maestro Arciere. [cite_start]Forza 6/25-45-65[cite: 13045].",false
Elmo del Silenzio,7,Elfi Daikinee,"Riservato a Kishdan. Esploratore in volo. [cite_start]Comando esteso livelli adiacenti[cite: 13055].",false
Goan,7,Elfi Daikinee,"Riservato a Maneos. Arma Simbiotica. [cite_start]Dona Furia Guerriera[cite: 13062].",false
Ciondolo del Trapasso,6,Elfi Daikinee,"Riservato a Irul. +1 COR/DIS. [cite_start]Trasmigra anima alla morte[cite: 13037].",false
Daga di Ossidiana,6,Divoratori di Vile-Tis,"Riservato a Kassar. [cite_start]Conferisce l'abilità Assassino[cite: 7287].",false
Insegna del Sangue,6,Divoratori di Vile-Tis,"Riservato a Ashkasa. +2.5cm Comando. [cite_start]Dona Sequenza Colpi a truppa[cite: 7290].",false
L'Alviram,8,Divoratori di Vile-Tis,"Riservato a Nekhar. [cite_start]Rilancia i 6 per ferire[cite: 7324].",false
Il Drako,9,Divoratori di Vile-Tis,"Riservato a Shakansa. [cite_start]Dissipa magie o rimuove abilità nemiche[cite: 7381].",false
Lama Vorace,0,Divoratori di Vile-Tis,"Costo: FOR-2. [cite_start]+1 Ferita se ne infligge 3+[cite: 7391].",false
[cite_start]Anello dell'Assenza,6,Divoratori di Vile-Tis,"Non bersagliabile se c'è alleato più vicino[cite: 7394].",false

```

### 7. `nexus.csv`

Elementi scenici speciali.

```csv
name,army_name,cost,resistance,structure,effect
Ucorno,Elfi Daikinee,10,8,5,"Alleanza Scarabeo. Difficoltà 7 per Fate/Fedeli. Fornisce Vigore. [cite_start]Può Trascinarsi, Bloccare o Colpire[cite: 13104]."
La Belva di Dracynran,Divoratori di Vile-Tis,9,8,7,"Alleanza Uccisore Nato. Fornisce Armatura Sacra o Arma Sacra. [cite_start]Emblema/30[cite: 7414]."

```

### 8. `magics.csv` (Magie e Miracoli unificati)

Contiene incantesimi e miracoli specifici.

```csv
name,type,path_deity,difficulty,cost_fervor,range,duration,effect
[cite_start]Presentimento,Magia,Primagia,5,1 Neutra,Speciale,Istantanea,"Guarda la prima carta avversaria[cite: 8]."
[cite_start]Egida Elementale,Magia,Primagia,Speciale,1 Neutra,Speciale,Istantanea,"Sostituisce un tentativo di contrasto[cite: 18]."
[cite_start]Palla di Fuoco,Magia,Fuoco,9,2 Fuoco,25 cm,Istantanea,"Tiro a FOR 8, Artiglieria Leggera a Zona[cite: 5201]."
Artiglio di Shaenre,Magia,Acqua (Riservata),7,2 Acqua,15 cm,Speciale,"Tiro FOR 6 Tossico/2. [cite_start]Shaenre +2 ATT/FOR[cite: 13125]."
[cite_start]Convocazione,Magia,Acqua (Riservata),8,3 Acqua,10 cm,Partita,"Shaenre invoca un Famiglio Fatato[cite: 13135]."
[cite_start]Rabbia della Iena,Magia,Tenebre/Acqua (Riservata),6,1 Tenebre/Acqua,Personale,Turno,"Spendi gemme per dadi combattimento extra[cite: 6300]."
[cite_start]Fuga Segreta,Magia,Acqua (Riservata),7,1 Acqua,Personale,Istantanea,"Velrys si teletrasporta vicino a un Divoratore amico[cite: 6321]."
[cite_start]Sconfessione Mistica,Miracolo,Vile-Tis,Speciale,1,Speciale,Istantanea,"Dissipa magia nemica appena lanciata[cite: 7472]."
[cite_start]Ombra della Bestia,Miracolo,Vile-Tis,6,1,Personale,Istantanea,"Fedele scompare e riappare a fine combattimento[cite: 7483]."
[cite_start]Inarrestabile,Miracolo,Vile-Tis,6,1,Aura Fede,Turno,"Wolfen ottiene bonus MOV o Implacabile dopo uccisioni[cite: 7497]."
[cite_start]Occhio di Earthè,Miracolo,Earthè,Somma Aspetti+3,1,50 cm,Partita,"Bersaglio acquisisce Prevedibile[cite: 13146]."
[cite_start]Elevazione,Miracolo,Earthè,RES bersaglio,2,20 cm,Istantanea,"Alleato con Volo effettua cambio livello gratuito[cite: 13153]."

```

### 9. `fighters.csv`

Contiene sia i profili base che quelli modificati dalle affiliazioni (gestiti come voci separate con riferimento all'affiliazione).
*Nota: i costi "base" includono il costo del profilo. Per i profili affiliati, il costo include l'eventuale costo di affiliazione obbligatorio.*

```csv
name,title,army_name,affiliation_name,rank_name,size_name,base_cost,mov,ini,att,for_str,dif,res,tir,courage,fear,discipline,power,faith,skills_list,spells_list
Arciere Daikinee,Truppa Regolare,Elfi Daikinee,,Regolare,Media,11,12.5,3,2,3,2,5,3,,,,,Rigenerazione/5,
[cite_start]Arciere Daikinee (Laureken),Truppa Regolare (Laureken),Elfi Daikinee,Armata di Laureken,Regolare,Media,11,12.5,3,2,3,2,5,3,,,,,Rigenerazione/5 (Schierabili 4 per carta)[cite: 12836],
Guerriero Daikinee (Mazza),Truppa Regolare,Elfi Daikinee,,Regolare,Media,12,12.5,3,3,6,3,5,,,,,Rigenerazione/5,
Numae,Guardiano Daikinee,Elfi Daikinee,,Regolare,Media,41,12.5,4,5,6,7,5,4,,,3,,Comando/10; Rigenerazione/5; Artefatto/1,
Maneos,Guardiano di Nuham,Elfi Daikinee,,Elite,Media,70,12.5,5,6,7,10,5,6,,,3,,Fine Lama; Colpo Maestro/2; Irremovibile; Rigenerazione/5,
Maneos (Nuham),Guardiano di Nuham (Affiliato),Elfi Daikinee,Nuham,Elite,Media,70,12.5,5,6,7,10,5,6,,,3,,Comando/10 (Bonus Nuham); Fine Lama; Colpo Maestro/2; [cite_start]Rigenerazione/5[cite: 12850],
Shaenre Sentinella,Sentinella Daikinee,Elfi Daikinee,,Iniziato,Media,35,12.5,4,2,4,4,4,4,,,2,4,,Acqua/Fatata; Fratello Sangue/Kurujai; Rigenerazione/5,"Artiglio di Shaenre"
Guerriero del Sangue,Truppa Regolare,Divoratori di Vile-Tis,,Regolare,Media,16,12.5,3,4,5,4,7,,1,,,4,,Ambidestro; Catene Massacro,
Guerriero del Sangue (Massacro),Vandalo del Massacro,Divoratori di Vile-Tis,Il Massacro,Regolare,Media,17,12.5,3,4,5,4,7,,2,,,4,,Ambidestro; Catene Massacro; [cite_start]+1 COR (Bonus Massacro)[cite: 7033],
Cacciatore di Teste,Truppa Regolare,Divoratori di Vile-Tis,,Regolare,Media,26,17.5,4,4,5,4,7,,5,,3,,,Uccisore Nato; Catene Massacro; [cite_start]Stella[cite: 7519],
Kassar il Fuggitivo,Eterno Fuggitivo,Divoratori di Vile-Tis,,Irregolare,Grande (Creatura),62,17.5,6,6,10,4,7,,6,,1,,,Esploratore; Flagello/Elementali; Paria; Spadaccino; [cite_start]Uccisore Nato[cite: 7517],
Kassar (Eclisse),Eterno Fuggitivo (Eclisse),Divoratori di Vile-Tis,L'Eclisse,Irregolare,Grande (Creatura),62,17.5,6,6,10,4,7,,6,,1,,,Bonus Flagello Eclisse; Esploratore; Paria; [cite_start]Spadaccino[cite: 7019],
Sophet Drahas,Adepto,Divoratori di Vile-Tis,,Adepto,Media,79,12.5,5,5,5,7,7,4,7,,4,5,,Consapevolezza; Contrattacco; Conc/2; [cite_start]Acqua/Tenebre[cite: 7519],"Stretta del Lich; Maestà"
Nemetis il Sacrilego,Devoto,Divoratori di Vile-Tis,,Devoto,Media,62,15,5,4,7,8,7,,,7,3,,0-1-2,Fedele Vile-Tis/15; Iconoclasta; Monaco-Guerriero; [cite_start]Uccisore Nato[cite: 7519],

```

### Note per l'importazione

1. **Costi Affiliazione**: Nel file `fighters.csv`, per i profili affiliati, il `base_cost` è stato calcolato sommando il costo base + il costo dell'affiliazione descritto nel regolamento (es. Massacro = Costo Rango, quindi +1 PA per un regolare).
2. **Statistiche**: I campi vuoti in `tir`, `courage`, `fear`, `power`, `faith` indicano che il modello non ha quella statistica (è `-` sulla carta).
3. **Stringhe Liste**: `skills_list` e `spells_list` sono stringhe delimitate da punto e virgola per facilitare il parsing e l'associazione successiva nel DB tramite script.
4. **Vincoli di Schieramento**: Le regole di esclusione (es. "No Mezzelfi in Dun-Scaith") non sono codificabili in un semplice CSV di dati statici, ma sono descritte nel campo `bonus_description` di `affiliations.csv` affinché la logica dell'applicazione (il validatore dell'Army Builder) possa implementarle.

Certamente. Ho preparato i file CSV **completi** basandomi sui Documenti di Armata forniti (Daikinee e Divoratori) e sulle regole generali.

**Nota Importante sull'importazione:**
Poiché le liste complete di *tutte* le magie e i miracoli di *tutti* i culti (File 2 e 3) genererebbero migliaia di righe superando i limiti di caratteri di questa risposta, ho incluso:

1. **Tutte** le Magie/Miracoli Universali e Primagia (accessibili a tutti).
2. **Tutte** le Magie/Miracoli specifici e riservati per **Daikinee** e **Divoratori**.
3. **Tutti** i Profili, Artefatti, Abilità e Affiliazioni presenti nei documenti.

Puoi copiare questi blocchi e salvarli come file `.csv` (es. `skills.csv`, `fighters.csv`, etc.).

### 1. `skills.csv` (Abilità Generali)

Estratto dal Regolamento .

```csv
name,has_value,description
Abominevole,false,"Test COR nemico con 2d6 tenendo il basso."
Accanito,false,"Rimosso a fine fase se ucciso. Conta come Ferita Critica."
Agguerrito,false,"I 5 nei test diventano 6."
Alleanza,true,"Può allearsi con il popolo X."
Amato dagli dei,false,"I 4 e 5 nei test diventano 6."
Ambidestro,false,"Guadagna dado attacco per ogni difesa riuscita."
Artefatto,true,"Può portare X artefatti."
Artificiere,false,"Piazza trappole ed esche."
Arto Aggiuntivo,false,"Scambia ATT e DIF a inizio passo d'arme."
Assassino,false,"Tira 3d6 per ferire e ne tiene 2 nel primo attacco dopo carica."
Assillo,false,"Può tirare e correre o marciare-tirare-marciare (-1 ai tiri)."
Audacia,false,"1 in COR non è fallimento. +1 ATT se tutti dadi in attacco."
Autorità,false,"Genera segnalini per manipolare attivazione e mischia."
Balzo,false,"Può saltare ostacoli e miniature."
Bersaglio,true,"Modifica difficoltà tiro nemico di X."
Brutale,false,"Infligge sempre malus di carica."
Carica Bestiale,false,"Dado attacco extra dopo carica riuscita."
Colossale,false,"Taglia Molto Grande (7 ferite, Possanza 4)."
Colpo da Maestro,true,"Sacrifica 2 dadi attacco per colpo a FOR + ATT + X."
Comando,true,"Trasmette COR e DIS entro X cm."
Concentrazione,true,"Distribuisce X punti su statistiche."
Consapevolezza,false,"Vede a 360° entro 20cm e ignora copertura."
Contrattacco,false,"Dado attacco extra per ogni difesa riuscita di 2+."
Costrutto,false,"Immune Paura/Tossico. DIS 0."
Credente,true,"Fornisce X punti fede extra o conta come X seguaci."
Destriero,false,"Dado attacco extra se non carica."
Devozione,true,"Sacrifica alleato per mana."
Disingaggio,true,"Disimpegna con difficoltà X su INI."
Disperato,false,"+1 INI/ATT/DIF se in inferiorità o contro valore superiore."
Effimero,true,"Test su 1d6 in mantenimento: se >= X perde ferita."
Enorme,false,"Taglia Molto Grande (6 ferite, Possanza 3)."
Esaltato,false,"1 in Divination non è fallimento."
Esploratore,false,"Schieramento avanzato nascosto."
Etereo,false,"Attraversa ostacoli, immune terreni difficili, riduce ferite di 1."
Evocatore,true,"Aumenta di X la possanza controllabile."
Fanatismo,false,"Test DIS se fallisce COR. +1 ferire se tutto in attacco."
Feroce,false,"Risultati Stordito diventano 1 Ferita."
Fine lama,false,"1 in Attacco non è fallimento."
Finta,false,"Annulla dado nemico dopo attacco riuscito."
Flagello,true,"Legge ferite una riga più in basso contro X."
Focus,false,"Apre i 5 in POT come 6."
Fortuna,false,"Rilancia un test una volta per turno."
Forza in Carica,true,"Sostituisce FOR con X in carica."
Fratello di Sangue,true,"Sconto costo e Istinto se vicini a X."
Furia Guerriera,false,"Dado extra in attacco ma obbligo tutti dadi in attacco."
Geniere,false,"Piazza barricate."
Gigantesco,false,"Taglia Molto Grande (8 ferite, Possanza 5)."
Giusto,false,"Immune Paura. +1 ATT se tutto in attacco."
Grido di Guerra,true,"Sostituisce COR con PAU X in carica."
Grido di raduno,false,"Recupera rotta e +1 COR armata una volta a partita."
Guarigione,true,"Cura ferita con 1d6 >= X."
Guerriero-Mago,false,"Contrattacco e casta magie mentre corre/carica."
Iconoclasta,false,"Usa nemici come seguaci."
Illuminato,false,"Apre i 5 in Divination come 6."
Immersione,false,"Muove in acqua senza penalità."
Immortale,true,"Bonus specifici per via (Luce/Tenebre/Destino)."
Immunità/Paura,false,"Non effettua test di Coraggio."
Immunità/Tossico,false,"Immune agli effetti del tossico."
Implacabile,true,"Movimenti inseguimento extra."
Infiltrazione,true,"Movimento pre-partita di X cm."
Insensibile,true,"Ignora magia/miracolo su 1d6 >= X."
Iperione,false,"Immune Paura. Causa Paura a Tenebre."
Irremovibile,false,"Non subisce malus di carica."
Istinto di Sopravvivenza,false,"Annulla ferita su 1d6 (6)."
Maestria degli Arcani,false,"Sacrifica POT per mana."
Maestro arciere,false,"Tiro supplementare."
Maledetto,false,"Non può rilanciare dadi né aprire i 6."
Martire,true,"Sacrifica salute per dare Fede al fedele."
Meccanico,true,"Ripara macchine su 1d6 >= X."
Mercenario,false,"Può essere assoldato da altri popoli."
Mira,false,"Aumenta FOR tiro ma malus su gittata."
Monaco-Guerriero,false,"Contrattacco e miracoli mentre corre/carica."
Mutageno,true,"Dadi extra per potenziare statistiche."
Negazione,false,"Censura/Contrasto senza linea di vista."
Nemico personale,true,"Bonus se uccide X."
Non-morto,false,"Immune Paura/Tossico. DIS 0."
Ossoduro,false,"Legge ferite una riga più in alto."
Parata,false,"1 in Difesa non è fallimento."
Paria,false,"Test Tattica con 2 dadi (peggiore) se presente."
Pietà,true,"Conserva X punti fede."
Posseduto,false,"Riduce penalità ferite di un livello."
Precisione,false,"Apre i 5 in Tiro come 6."
Prevedibile,false,"Carta sempre visibile."
Rapidità,false,"Triplica MOV in corsa/carica."
Recupero,true,"Recupera X gemme extra."
Ricarica rapida,false,"Tiro extra con malus -2."
Riflessi,false,"Apre i 5 in INI come 6."
Rigenerazione,true,"Recupera ferite con 1d6 >= X in mantenimento."
Rigore,false,"1 in DIS non è fallimento."
Rinforzi,false,"Torna in gioco dopo morte su 5+."
Riorientamento,false,"Cambia fronte liberamente a inizio fase."
Riparo,true,"Nessun atterraggio entro X cm."
Risolutezza,true,"+X a un test di INI, ATT, DIF o COR."
Robustezza,false,"Ignora penalità ferita leggera/stordito."
Rozzo,false,"Apre i 5 in ATT. +1 Possanza in carica."
Schivata,false,"Apre i 5 in DIF."
Selenita,false,"Bonus variabili in base a 1d6 a inizio partita."
Selvaggio,true,"+1 INI/ATT/DIF se lontano X da amici."
Senza Patria,false,"Acquisisce abilità più diffusa nell'armata."
Sequenza di Colpi,true,"Fino a X dadi extra con penalità -1 ATT/DIF."
Spadaccino,false,"Dado riserva usabile dopo."
Spirito,true,"1 in POT non è fallimento per elemento X."
Stratega,false,"Apre i 5 in DIS."
Taumaturgo,false,"Aura fede aumenta 5cm per ferita."
Tiratore d'élite,false,"1 in Tiro non è fallimento."
Tiro in Assalto,false,"Tira mentre carica (Diff 7)."
Tiro Istintivo,false,"Ignora coperture/malus. Ripartizione migliorata."
Tiro di Reazione,false,"Tira quando caricato (Diff 7)."
Tossico,true,"Genera dadi tossico. Infligge ferite dirette a FOR X con RES 0."
Uccisore Nato,false,"Dado extra in attacco. Supera auto test COR <= proprio COR."
Vivacità,false,"1 in INI non è fallimento."
Volo,false,"Movimento aereo e livelli di altitudine."
Vulnerabile,false,"Ferite subite aumentate di un livello."

```

### 2. `artifacts.csv` (Artefatti Generici e Specifici)

Include pozioni, rune e artefatti specifici dai libri Daikinee e Divoratori .

```csv
name,cost,army_name,description,is_relic
Pozione Minore di Forza,2,Generico,"+2 FOR per un turno.",false
Pozione Maggiore di Forza,4,Generico,"+3 FOR per un turno.",false
Pozione Suprema di Forza,6,Generico,"+4 FOR per un turno.",false
Pozione Curativa,7,Generico,"Recupera 1 ferita (Solo Personaggi).",false
Runa della Guarigione Minore,4,Generico,"Conferisce Cura/6.",false
L'Arco Spirito,10,Elfi Daikinee,"Riservato a Kurujai. Arma Simbiotica. Dona Maestro Arciere. Forza 6/25-45-65. Genera mana uccidendo.",false
Elmo del Silenzio,7,Elfi Daikinee,"Riservato a Kishdan. Esploratore in volo se nessun nemico a 10cm. Comando esteso livelli adiacenti.",false
Goan,7,Elfi Daikinee,"Riservato a Maneos. Arma Simbiotica. Dona Furia Guerriera. Può scambiare Furia per Uccisore Nato.",false
Ciondolo del Trapasso,6,Elfi Daikinee,"Riservato a Irul. +1 COR/DIS. Trasmigra anima in alleato alla morte.",false
L'Argento Vivo,8,Elfi Daikinee,"Riservato a Onental. Movimento ingaggio extra a inizio combattimento.",false
Sparti-Vento,8,Elfi Daikinee,"Riservato a Kishdan. Due cambi livello. Carica Bestiale in picchiata da liv 2.",false
Il Carapace d'Anura,10,Elfi Daikinee,"Riservato a Maneos. Armatura Simbiotica. Rigenerazione extra. Dona Riparazione a Nexus.",false
Bracciale d'Agata,7,Elfi Daikinee,"Riservato a Solana. +2 Potenziale. Spende gemme per Arma Simbiotica o Tossico.",false
Ramo di Elandir,6,Elfi Daikinee,"Riservato a Shaenre II. Spirito Acqua. Dona Martire/Devozione/Mana a Fate/Nexus.",false
Frecce di Erpice,8,Elfi Daikinee,"Riservato a Dhianiss. Tiro indiretto (-1). Lancia miracolo su bersaglio colpito.",false
Strali d'Alabastro,6,Elfi Daikinee,"Solo Personaggi con Arco. FOR 6. Impedisce cure al bersaglio.",false
Lemure Fatato,7,Elfi Daikinee,"Solo Personaggi. Consapevolezza e Credente/1.",false
Scettro dello Scarabeo,6,Elfi Daikinee,"Solo Fedeli. Spende 1 FT per annullare ferita su Daikinee (Rigenerazione/X).",false
Daga di Ossidiana,6,Divoratori di Vile-Tis,"Riservato a Kassar. Conferisce l'abilità Assassino.",false
Insegna del Sangue,6,Divoratori di Vile-Tis,"Riservato a Ashkasa. +2.5cm Comando. Dona Sequenza Colpi a truppa con Contrattacco.",false
L'Alviram,8,Divoratori di Vile-Tis,"Riservato a Nekhar. Rilancia i 6 per ferire. Malus tattica se non ferisce.",false
Maschera della Ferocia,10,Divoratori di Vile-Tis,"Riservato a Nekhar. Accanito e Furia Guerriera. Vincolo dadi attacco.",false
Arco dei Tormenti,12,Divoratori di Vile-Tis,"Riservato a Nekhar. +10cm Comando. Accumula segnalini uccisioni per bonus (Fede, Cura, Flagello).",false
Il Furore di Ynkaro,5,Divoratori di Vile-Tis,"Riservato a Velrys. Scambia INI per FOR.",false
Rete di Catene,10,Divoratori di Vile-Tis,"Riservato a Velrys/Sylenia. Tutte le Catene. +2 Potenziale. Cumula Corsa e Magia.",false
Marchio della Bestia,9,Divoratori di Vile-Tis,"Riservato a Bysra. Accumula segnalini su 1 o uccisioni. A 3 segnalini: Posseduto, Negazione, +2 Stats.",false
Gemma di Sangue,7,Divoratori di Vile-Tis,"Riservato a Shakansa. Riserva infinita. Recupera acqua su ferite/uccisioni.",false
Il Drako,9,Divoratori di Vile-Tis,"Riservato a Shakansa. Spende gemme per dissipare effetti o rimuovere abilità nemici.",false
Lama Vorace,0,Divoratori di Vile-Tis,"Costo: FOR-2. +1 Ferita se ne infligge 3+.",false
Anello dell'Assenza,6,Divoratori di Vile-Tis,"Non bersagliabile se c'è alleato più vicino.",false
Talismano delle Cinque Lame,5,Divoratori di Vile-Tis,"Solo Fedeli. Flagello/Fedele. +FOR spendendo FT.",false
Le Spoglie del Sanguinario,17,Divoratori di Vile-Tis,"Reliquia. Solo Fedeli Grande con Uccisore. Abominevole. Prodigio: Sequenza Colpi.",true

```

### 3. `nexus.csv`

Estratto da e.

```csv
name,army_name,cost,resistance,structure,effect
Ucorno,Elfi Daikinee,10,8,5,"Alleanza Scarabeo. Difficoltà 7 per Fate/Fedeli. Fornisce Vigore. Può Trascinarsi, Bloccare o Colpire."
La Belva di Dracynran,Divoratori di Vile-Tis,9,8,7,"Alleanza Uccisore Nato. Fornisce Armatura Sacra o Arma Sacra. Emblema/30."

```

### 4. `magics.csv`

Include Primagia e le Magie specifiche di Daikinee e Divoratori .

```csv
name,type,path_deity,difficulty,cost_fervor,range,duration,effect
Presentimento,Magia,Primagia,5,1 Neutra,Speciale,Istantanea,"Guarda la prima carta avversaria."
Egida Elementale,Magia,Primagia,Speciale,1 Neutra,Speciale,Istantanea,"Sostituisce un tentativo di contrasto."
Aura d'Autorità,Magia,Primagia,POT Mago +4,Speciale,Tutto il campo,Turno,"Costo gemme pari a meta DIS comandante. Ottiene 1 segnalino Autorità."
Catene Elementali,Magia,Primagia,DIS bersaglio,2 Neutre,20 cm,Turno,"Difficoltà min 5. Bersaglio non può inseguire."
Freccia di Mana,Magia,Primagia,POT Mago +4,1 Neutra,20 cm,Istantanea,"Tiro per ferire con FOR pari a POT mago."
Galvanizzazione Mistica,Magia,Primagia,POT Mago +3,2 Neutre,15 cm,Turno,"+1 a INI, ATT, DIF, TIR, POT, Divination."
Guarigione Minore,Magia,Primagia,7,2 Neutre,10 cm,Istantanea,"Recupera 1 ferita."
Marcia Forzata,Magia,Primagia,6,2 Neutre,15 cm,Istantanea,"Bersaglio libero muove di 5cm extra."
Guerriero Elementale,Magia,Primagia,POT Mago +3,2 Neutre,Personale,Turno,"Mago ottiene abilità Guerriero Mago."
Artiglio di Shaenre,Magia,Acqua (Riservata),7,2 Acqua,15 cm,Speciale,"Tiro FOR 6 Tossico/2. Shaenre +2 ATT/FOR."
Convocazione,Magia,Acqua (Riservata),8,3 Acqua,10 cm,Partita,"Shaenre invoca un Famiglio Fatato."
Rabbia della Iena,Magia,Tenebre/Acqua (Riservata),6,1 Tenebre/Acqua,Personale,Turno,"Spendi gemme per dadi combattimento extra."
Fuga Segreta,Magia,Acqua (Riservata),7,1 Acqua,Personale,Istantanea,"Velrys si teletrasporta vicino a un Divoratore amico."
Patto degli Incatenati,Magia,Acqua (Riservata),5,2 Acqua,15 cm,Turno,"Bersaglio con Catene perde 1 dado ma da bonus al Mago."
Arte della Furia,Magia,Acqua (Riservata),5,1 Acqua,Personale,Speciale,"Ottiene 2 punti Furia. Converte gemme in Furia."
Sconfessione Mistica,Miracolo,Vile-Tis,Speciale,1,Speciale,Istantanea,"Dissipa magia nemica appena lanciata."
Ombra della Bestia,Miracolo,Vile-Tis,6,1,Personale,Istantanea,"Fedele scompare e riappare a fine combattimento."
Aura di Profanazione,Miracolo,Vile-Tis,DIS bersaglio,1,30 cm,Turno,"Rende Iconoclasta un fedele (o toglie Iconoclasta)."
Inarrestabile,Miracolo,Vile-Tis,6,1,Aura Fede,Turno,"Wolfen ottiene bonus MOV o Implacabile dopo uccisioni."
Voracità della Bestia,Miracolo,Vile-Tis,7,2,Aura Fede,Turno,"Bersaglio ottiene Furia Guerriera obbligatoria."
Personificazione Estemporanea,Miracolo,Vile-Tis (Sylenia),7,1,Personale,Istantanea,"Sylenia scambia stat con alleato per una prova."
Occhio di Earthè,Miracolo,Earthè,Somma Aspetti+3,1,50 cm,Partita,"Bersaglio acquisisce Prevedibile."
Elevazione,Miracolo,Earthè,RES bersaglio,2,20 cm,Istantanea,"Alleato con Volo effettua cambio livello gratuito."
Sciame,Miracolo,Earthè,5,1,15 cm,Turno,"Difficoltà azioni contro bersaglio +3. Portata aumenta con Fata."
Resurrezione del Mandigorn,Miracolo,Earthè,8,3,Speciale,Istantanea,"Riporta in gioco un Mandigorn eliminato."
Campione di Smeraldo,Miracolo,Earthè (Meari),COR/PAU bersaglio,2,20 cm,Turno,"Bersaglio diventa Personaggio."
Nemico della Natura,Miracolo,Earthè (Dhianiss),7,2,10 cm,Turno,"Bersaglio subisce danno muovendosi e malus a tiro/magia."
Tocco di Earthè,Miracolo,Earthè (Prescelta),5+POSS,1,20 cm,Istantanea,"Cura Fata/Nexus/Famiglio."

```

### 5. `fighters.csv` (Profili Base e Modificati)

Include i profili base dei file 9 e 11 e le varianti per affiliazione.
**Logica:** `base_cost` per i profili affiliati include già il costo dell'affiliazione. `skills_list` elenca le abilità separate da `;`.
*Nota: i campi vuoti (es. Fear per chi ha Courage) sono lasciati vuoti.*

```csv
name,title,army_name,affiliation_name,rank_name,size_name,base_cost,mov,ini,att,for_str,dif,res,tir,courage,fear,discipline,power,faith,skills_list,spells_list
Arciere Daikinee,Truppa Regolare,Elfi Daikinee,,Regolare,Media,11,12.5,3,2,3,2,5,3,,,,,Rigenerazione/5,
Arciere Daikinee (Laureken),Truppa Regolare,Elfi Daikinee,Armata di Laureken,Regolare,Media,11,12.5,3,2,3,2,5,3,,,,,Rigenerazione/5 (4 per carta),
Guerriero Daikinee (Mazza),Truppa Regolare,Elfi Daikinee,,Regolare,Media,12,12.5,3,3,6,3,5,,,,,Rigenerazione/5,
Guerriero Daikinee (Spada),Truppa Regolare,Elfi Daikinee,,Regolare,Media,12,12.5,4,3,4,3,5,,3,,,,,Rigenerazione/5,
Musico Daikinee,Truppa Regolare,Elfi Daikinee,,Regolare,Media,13,12.5,3,3,4,3,5,,3,,2,,Comando/10; Rigenerazione/5,
Porta-Stendardo Daikinee,Truppa Regolare,Elfi Daikinee,,Regolare,Media,13,12.5,3,3,4,3,5,,4,,1,,Comando/10; Rigenerazione/5,
Arciere Veterano,Truppa Veterana,Elfi Daikinee,,Veterano,Media,14,12.5,3,2,4,3,5,4,4,,,,,Assillo; Rigenerazione/5,
Guardiano Daikinee (Spada),Truppa Veterana,Elfi Daikinee,,Veterano,Media,15,12.5,3,3,5,4,6,,4,,1,,,Esploratore; Rigenerazione/5,
Guardiano Daikinee (Mazza),Truppa Veterana,Elfi Daikinee,,Veterano,Media,15,12.5,3,3,7,3,6,,4,,1,,,Esploratore; Rigenerazione/5,
Fuco Daikinee,Truppa Veterana,Elfi Daikinee,,Veterano,Media,16,12.5,4,4,6,3,5,,6,,2,,,Risolutezza/3; Essere del Destino/3; Rigenerazione/5; Fata; Protettori,
Scarabeo Gigante,Creatura,Elfi Daikinee,,Creatura,Grande (Creatura),31,12.5,2,4,8,3,9,,-5,,0,1,,Rozzo; Immunità/Paura; Cura/5; Rigenerazione/5; Espandere Corazza,
Guerriero Mandigorn,Creatura Speciale,Elfi Daikinee,,Creatura,Grande (Creatura),56,15/20,2,5,10,2,12,,-7,,1,,,Volo; Carica Bestiale; Essere del Destino/3; Implacabile/1; Rigenerazione/5; Fata,
Silfide Daikinee,Creatura Speciale,Elfi Daikinee,,Speciale,Media,14,12.5/20,3,3,4,4,3,,5,,2,,,Volo; Credente/1; Essere del Destino/3; Rigenerazione/5; Fata; Le Silfidi,
Esploratore Daikinee,Creatura Speciale,Elfi Daikinee,,Speciale,Media,17,12.5,4,4,4,3,5,3,4,,2,1,1,Esploratore; Mira; Rigenerazione/5,
Zéfiro Daikinee,Creatura Speciale,Elfi Daikinee,,Speciale,Media,20,12.5,4,5,5,4,5,3,5,,2,,,Balzo; Feroce; Rigenerazione/5; Gli Zefiri,
Lama di Smeraldo,Creatura Speciale,Elfi Daikinee,,Speciale,Media,26,12.5,5,6,7,4,5,,6,,3,,,Assassino; Rapidità; Rigenerazione/5; Armatura Simbiotica,
Sentinella Daikinee (1),Truppa Elite,Elfi Daikinee,,Elite,Media,18,12.5,4,4,6,5,6,,5,,3,,,Finta; Ambidestro; Rigenerazione/5,
Sentinella Daikinee (2),Truppa Elite,Elfi Daikinee,,Elite,Media,18,12.5,4,4,6,5,6,,5,,3,1,1,Spadaccino; Ambidestro; Rigenerazione/5,
Guerriera Silfide,Truppa Elite,Elfi Daikinee,,Elite,Media,21,12.5/20,3,4,6,4,5,,5,,2,,,Volo; Audacia; Essere del Destino/3; Rigenerazione/5; Fata,
Guerriero Scarabeo,Truppa Elite,Elfi Daikinee,,Elite,Media,25,12.5,4,5,6,4,8,,5,,2,,,Fine Lama; Colpo da Maestro/2; Rigenerazione/5; Armatura Simbiotica,
Guerriero Scarabeo (Laureken),Guardia Reale,Elfi Daikinee,Armata di Laureken,Elite,Media,27,12.5,4,5,7,4,8,,5,,2,,,Fine Lama; Colpo da Maestro/2; Rigenerazione/5; Armatura Simbiotica; Giusto,
Guerriero Scarabeo (Anura),Protettore Rovine,Elfi Daikinee,Esiliati di Anura,Elite,Media,28,12.5,4,5,6,4,8,,5,,2,,,Fine Lama; Colpo da Maestro/2; Rigenerazione/5; Armatura Simbiotica; Furia Guerriera,
Cavalieri su Cervo Volante,Truppa Elite,Elfi Daikinee,,Elite,Grande (Cavalleria),37,12.5/17.5,2,4,7,4,8,4,6,,3,,,Volo; Tiro Istintivo; Destriero; Rigenerazione/5,
Guerriera dei Sogni,Mistico Iniziato,Elfi Daikinee,,Iniziato,Media,26,12.5,4,3,3,3,8,5,5,,4,2,,Acqua/Simbiosi; Guerriero Mago; Rigenerazione/5; Fata; Arma/Armatura Simbiotica,
Prescelta di Earthè,Fedele Devoto,Elfi Daikinee,,Devoto,Media,22,12.5,4,3,3,3,5,4,6,,4,,1-1-0,Fedele di Earthè/10; Monaco-Guerriero; Tiro di Reazione; Rigenerazione/5,
Irul Capo Tribù,Personaggio Regolare,Elfi Daikinee,,Regolare,Media,25,12.5,3,2,3,6,2,,4,,3,,,Comando/10; Rigenerazione/5,
Numae Guardiano,Personaggio Regolare,Elfi Daikinee,,Regolare,Media,41,12.5,4,5,6,7,5,4,,3,,,Comando/10; Rigenerazione/5; Amico delle Fate,
Kaeliss il Silenzioso,Personaggio Regolare,Elfi Daikinee,,Regolare,Media,42,12.5,5,4,3,4,4,4,6,,5,,,Esploratore; Finta; Flagello/Tiratori; Paria,
Kurujai Arciere,Personaggio Regolare,Elfi Daikinee,,Regolare,Media,49,12.5,5,4,4,6,5,5,6,,4,1,4,2,Tiro Istintivo; Fratello Sangue/Shaenre; Rigenerazione/5,
Kaeliss Voce dei Paria,Personaggio Regolare,Elfi Daikinee,,Regolare,Media,50,12.5,5,4,4,5,5,7,,,4,,,Esploratore; Finta; Paria; Flagello/Tiratori; Tiro Istintivo; Voce dei Paria,
Onental il Contrabbandiere,Personaggio Veterano,Elfi Daikinee,,Veterano,Media,41,12.5,5,4,5,6,5,,5,6,,4,,,Ambidestro; Bersaglio/+2; Rigenerazione/5; Danza di Morte,
Onental (Indatte),Personaggio Veterano,Elfi Daikinee,Indatte,Veterano,Media,41,12.5,5,4,5,6,5,,5,6,,4,,,Ambidestro; Bersaglio/+2; Rigenerazione/5; Danza di Morte; Autorità,
Ehryl la Belva,Personaggio Speciale,Elfi Daikinee,,Speciale,Media,51,12.5,5,6,5,6,5,6,,4,2,1,4,,Esploratore; Assillo; Rigenerazione/5; La Belva,
Kishdan Guerriero Silfide,Personaggio Elite,Elfi Daikinee,,Elite,Media,55,12.5/20,5,7,5,6,V,6,3,,1,,,Volo; Comando/15; Audacia; Essere del Destino/2; Rigenerazione/5; Fata,
Maneos,Personaggio Elite,Elfi Daikinee,,Elite,Media,70,12.5,5,6,7,10,5,6,3,,,,,Fine Lama; Colpo da Maestro/2; Irremovibile; Rigenerazione/5; Guerriero Scarabeo,
Maneos (Nuham),Personaggio Elite,Elfi Daikinee,Nuham,Elite,Media,70,12.5,5,6,7,10,5,6,3,,,,,Fine Lama; Colpo da Maestro/2; Irremovibile; Rigenerazione/5; Guerriero Scarabeo; Comando/10,
Shaenre Sentinella,Personaggio Iniziato,Elfi Daikinee,,Iniziato,Media,35,12.5,4,2,4,4,4,4,,4,2,4,,Acqua/Fatata; Fratello di Sangue/Kurujai; Rigenerazione/5,"Artiglio di Shaenre",
Solana Guerriera Sogni,Personaggio Iniziato,Elfi Daikinee,,Iniziato,Media,60,12.5,5,4,8,6,6,6,,4,3,,Acqua/Simbiosi; Guerriero-Mago; Essere del Destino/2; Balzo; Rigenerazione/5; Fata; Guerriero Sogni,
Shaenre Guardiana,Personaggio Adepto,Elfi Daikinee,,Adepto,Media,74,12.5,6,3,3,4,3,5,4,5,4,2,6,,Acqua e Terra/Fatata e Tellurica; Audacia; Credente/1; Fratello di Sangue/Kurujai; Rigenerazione/5,"Artiglio di Shaenre; Convocazione",
Meari il Protettore,Personaggio Devoto,Elfi Daikinee,,Devoto,Media,27,12.5,3,3,4,4,5,3,6,2,3,,,-/-/-,"Fedele di Earthé/10; Rigenerazione/5; Campione di Smeraldo",
Dhianiss Dardo Earthè,Personaggio Zelota,Elfi Daikinee,,Zelota,Media,67,12.5,5,5,6,5,5,4,6,4,2,1,0,Fedele di Earthè/12.5; Monaco-Guerriero; Infiltrazione/12.5; Bersaglio/+1; Rigenerazione/5,Nemico della Natura
Guerriero del Sangue,Truppa Regolare,Divoratori di Vile-Tis,,Regolare,Media,16,12.5,3,4,5,4,7,,1,,4,,,Ambidestro; Catene Massacro,
Guerriero del Sangue (Massacro),Truppa Regolare,Divoratori di Vile-Tis,Il Massacro,Regolare,Media,17,12.5,3,4,5,4,7,,2,,4,,,Ambidestro; Catene Massacro,
Arciere del Sangue,Truppa Regolare,Divoratori di Vile-Tis,,Regolare,Media,18,12.5,3,3,4,5,4,4,1,,4,,,Ambidestro; Catene Massacro; Arco,
Zanna di Vile-Tis,Truppa Regolare,Divoratori di Vile-Tis,,Regolare,Media,27,15,4,4,8,4,7,,,-5,1,,,Uccisore Nato; Catene Massacro,
Vorace,Truppa Regolare,Divoratori di Vile-Tis,,Regolare,Media,27,15,4,4,7,5,7,,,,-5,1,,,Uccisore Nato; Catene Ferocia,
Cacciatore di Teste,Truppa Regolare,Divoratori di Vile-Tis,,Regolare,Media,26,17.5,4,3,5,5,7,7,,-5,2,,,Uccisore Nato; Catene Massacro; Stella,
Lupa Funesta (Scaith),Truppa Regolare,Divoratori di Vile-Tis,Dun-Scaith,Regolare,Media,25,17.5,5,4,7,3,6,,,-5,,,,,Contrattacco; Uccisore Nato; Catene Massacro,
Cacciatore di Vile-Tis,Truppa Veterana,Divoratori di Vile-Tis,,Veterano,Media,31,17.5,4,3,5,4,6,3,5,,1,,,Assillo; Uccisore Nato; Catene Massacro; Stella,
Razziatore di Vile-Tis (1),Truppa Veterana,Divoratori di Vile-Tis,,Veterano,Media,30,15,5,5,7,5,8,,,-6,1,,,Vivacità; Uccisore Nato; Catene Ferocia,
Razziatore di Vile-Tis (2),Truppa Veterana,Divoratori di Vile-Tis,,Veterano,Media,31,15,5,5,7,5,8,,1,,-6,1,,,Furia Guerriera; Uccisore Nato; Catene Massacro,
Mane Divoratore (1),Creatura,Divoratori di Vile-Tis,Dun-Scaith,Creatura,Media,41,12.5,3,6,13,3,8,,,-8,,,,,Rigenerazione/5; Non-Morto; Catene Ferocia,
Mane Divoratore (2),Creatura,Divoratori di Vile-Tis,Dun-Scaith,Creatura,Media,27,15,3,5,9,2,6,,,-7,,,,,Rigenerazione/5; Non-Morto; Catene Ferocia,
Mane Divoratore (3),Creatura,Divoratori di Vile-Tis,Dun-Scaith,Creatura,Media,35,15,3,5,11,3,7,,,-7,1,,,Rigenerazione/5; Non-Morto; Catene Ferocia,
Il Korgan,Speciale,Divoratori di Vile-Tis,,Speciale,Media,16,15,4,4,7,3,6,,,0,-5,,,Balzo; Furia Guerriera; Catene Ferocia,
Eclissante,Speciale,Divoratori di Vile-Tis,,Speciale,Media,34,15,5,5,7,5,5,,,-6,2,,,Assassino; Uccisore Nato; Catene Ferocia,
Maestra d'Armi Eclissante,Speciale,Divoratori di Vile-Tis,L'Eclisse,Speciale,Media,36,15,5,6,8,5,6,,,-6,3,,,Assassino; Finta; Uccisore Nato; Catene Calamità,
Evisceratore,Elite,Divoratori di Vile-Tis,,Elite,Media,28,12.5,4,5,8,5,6,,,2,6,,,Esploratore; Assassino; Furia Guerriera; Ambidestro; Catene Calamità; Colpo Circolare,
Capocaccia di Vile-Tis,Elite,Divoratori di Vile-Tis,,Elite,Media,49,15,4,4,6,5,10,4,,-7,2,,,Artiglieria Leggera Perforante; Posseduto; Tiro Istintivo; Uccisore Nato; Catene Calamità,
Carnivoro (1),Elite,Divoratori di Vile-Tis,,Elite,Grande (Creatura),50,15,5,5,9,6,10,,,-7,2,,,Posseduto; Uccisore Nato; Catene Calamità,
Carnivoro (2),Elite,Divoratori di Vile-Tis,,Elite,Grande (Creatura),50,15,5,5,8,6,11,,,-7,2,,,Posseduto; Uccisore Nato; Catene Calamità,
Carnivoro (Resistenza),Elite,Divoratori di Vile-Tis,,Elite,Grande (Creatura),57,15,5,5,9,6,11,,2,,-8,,,Contrattacco; Posseduto; Uccisore Nato; Catene Calamità,
Carnivoro (Dolore),Elite,Divoratori di Vile-Tis,,Elite,Grande (Creatura),58,15,5,5,9,6,11,1,2,,-8,,,Sequenza di Colpi/1; Posseduto; Uccisore Nato; Catene Calamità,
Carnivoro (Forza),Elite,Divoratori di Vile-Tis,,Elite,Grande (Creatura),55,15,5,5,9,6,11,,,-8,2,1,,Colpo da Maestro/1; Posseduto; Uccisore Nato; Catene Calamità,
Tiranno di Vile-Tis,Elite,Divoratori di Vile-Tis,,Elite,Grande (Creatura),70,15,5,6,11,6,11,,,-8,3,,,Accanito; Posseduto; Uccisore Nato; Catene Calamità,
Adepto dei Massacri,Mistico Iniziato,Divoratori di Vile-Tis,,Iniziato,Media,26,12.5,4,5,6,5,V,,7,6,2,2,,Tenebre/Ululati; Guerriero-Mago; Esploratore; Ambidestro; Catene Massacro/Calamità,
Signore dei Massacri (Impuro),Mistico Iniziato,Divoratori di Vile-Tis,L'Impuro,Iniziato,Media,25,12.5,4,5,6,5,7,,6,2,2,,Acqua/Tormenti; Guerriero-Mago; Esploratore; Ambidestro; Catene Massacro/Ferocia,
Signore dei Massacri (1),Mistico Iniziato,Divoratori di Vile-Tis,,Iniziato,Media,35,17.5,4,4,8,5,7,,-6,2,2,,Acqua/Tormenti; Guerriero-Mago; Furia Guerriera; Uccisore Nato; Catene Massacro/Calamità,
Signore dei Massacri (2),Mistico Iniziato,Divoratori di Vile-Tis,,Iniziato,Media,36,15,4,5,7,6,7,,-6,2,2,,Acqua/Tormenti; Guerriero-Mago; Sequenza di Colpi/1; Uccisore Nato; Catene Massacro/Ferocia,
Profanatore di Templi (Impuro),Fedele Devoto,Divoratori di Vile-Tis,L'Impuro,Devoto,Media,25,12.5,4,5,6,5,7,,5,3,,,0-1-1,Fedele di Vile-Tis//12.5; Iconoclasta; Monaco-Guerriero; Insensibile/4; Ambidestro; Catene Perversione/Massacro,
Profanatore di Templi,Fedele Devoto,Divoratori di Vile-Tis,,Devoto,Media,35,15,4,4,7,5,8,,-6,3,,,0-1-1,Fedele di Vile-Tis//15; Iconoclasta; Monaco-Guerriero; Insensibile/4; Uccisore Nato; Catene Perversione/Massacro,
Kassar il Fuggitivo,Personaggio Irregolare,Divoratori di Vile-Tis,,Irregolare,Grande (Creatura),62,17.5,6,6,10,4,7,,,-6,1,,,Esploratore; Flagello/Elementali; Paria; Spadaccino; Uccisore Nato,
Kassar (Eclisse),Personaggio Irregolare,Divoratori di Vile-Tis,L'Eclisse,Irregolare,Grande (Creatura),62,17.5,6,6,10,4,7,,,-6,1,,,Bonus Flagello Eclisse; Esploratore; Paria; Spadaccino; Uccisore Nato,
Ashkasa Guerriero Sangue,Personaggio Regolare,Divoratori di Vile-Tis,,Regolare,Media,43,12.5,5,5,5,7,7,,,6,3,,,Comando/12.5; Audacia; Ambidestro; Catene Massacro,
Zeiren I,Personaggio Regolare,Divoratori di Vile-Tis,,Regolare,Media,62,15,6,5,9,6,7,,,-7,0,A,,Nemico Personale/Isakar; Implacabile/1; Mercenario; Uccisore Nato; Catene Ferocia,
Kalyar il Risvegliato,Personaggio Veterano,Divoratori di Vile-Tis,,Veterano,Media,70,15,5,5,7,8,7,,,-7,3,,1,Comando/15; Uccisore Nato; Catene Massacro,
Zeiren II,Personaggio Speciale,Divoratori di Vile-Tis,,Speciale,Media,72,15,6,6,10,8,8,,,-7,0,A,,Nemico Personale/Isakar; Implacabile/1; Selvaggio/10; Risolutezza/2; Uccisore Nato; Catene Ferocia,
Kalyar Capo Muta,Personaggio Speciale,Divoratori di Vile-Tis,,Speciale,Media,76,15,5,6,7,8,8,,,-7,3,A,,Comando/15; Vivacità; Uccisore Nato; Catene Calamità,
Meyleen Eclissante,Personaggio Speciale,Divoratori di Vile-Tis,,Speciale,Media,59,15,6,4,6,7,5,,,-6,3,A,,Comando/15; Assassino; Uccisore Nato; Maestra d'Armi Eclissante; Catene Massacro,
Managarm la Traditrice,Personaggio Speciale,Divoratori di Vile-Tis,,Speciale,Media,78,15,6,6,6,6,6,,-7,3,,1,Nemico Personale/Onyx; Assassino; Finta; Uccisore Nato; Ambidestro; Catene Massacro/Calamità,
Scupolo Evisceratore,Personaggio Elite,Divoratori di Vile-Tis,,Elite,Media,74,12.5,4,6,9,7,V,,,7,2,,A,Esploratore; Assassino; Furia Guerriera; Uccisore Nato; Ambidestro; Colpo Circolare,
Ranghor Capo Muta,Personaggio Elite,Divoratori di Vile-Tis,Dun-Scaith,Elite,Grande (Creatura),98,15,6,6,9,11,V,,-8,5,,A,Comando/15; Posseduto; Uccisore Nato; Tiranno di Vile-Tis; Catene Calamità,
Nekhar l'Estatico,Personaggio Elite,Divoratori di Vile-Tis,L'Estasi,Elite,Grande (Creatura),160,15,8,8,6,12,V,,-10,6,,A,Comando/15; Posseduto; Ossoduro; Implacabile/2; Uccisore Nato; Catene Calamità,
Bysra Sciamano Nero,Personaggio Iniziato,Divoratori di Vile-Tis,,Iniziato,Media,40,15,4,3,4,6,7,,,-7,3,3,,Acqua/Ululati; Uccisore Nato; Catene Perversione,
Bysra Vagabondo Nero,Personaggio Iniziato,Divoratori di Vile-Tis,,Iniziato,Media,60,15,4,4,7,5,7,,,-7,3,4,,Acqua/Mormorii/Ululati; Guerriero-Mago; Uccisore Nato; Catene Massacro/Perversione,
Velrys Principe Impuri,Personaggio Adepto,Divoratori di Vile-Tis,,Adepto,Media,79,12.5,5,5,5,10,7,,,7,4,5,,Acqua/Tenebre/Ctonia/Ululati; Consapevolezza; Contrattacco; Concentrazione/2 (Ini-Att-Res); Catene Calamità,"Fuga Segreta; Rabbia della Iena"
Shakansa Maestro Massacri,Personaggio Adepto,Divoratori di Vile-Tis,,Adepto,Media,108,17.5,5,6,6,7,9,,-8,4,4,,Acqua/Fuoco/Tormenti/Ululati; Guerriero-Mago; Comando/15; Furia Guerriera; Uccisore Nato; Catene Massacro/Calamità,"Patto degli Incatenati; Arte della Furia"
Nemetis il Sacrilego,Personaggio Devoto,Divoratori di Vile-Tis,,Devoto,Media,62,15,5,4,7,8,7,,,-6,3,,0-1-2,Fedele Vile-Tis/15; Iconoclasta; Monaco-Guerriero; Uccisore Nato; Catene Massacro/Perversione,
Sylenia Sangue Smeraldo,Personaggio Zelota,Divoratori di Vile-Tis,,Zelota,Media,72,12.5,6,6,5,7,V,,,7,2,,1-1-2,Fedele Vile-Tis/17.5; Iconoclasta; Monaco-Guerriero; Tiro Istintivo; Rigenerazione/5; Ambidestro; Mimic; Catene Calamità/Perversione,Personificazione Estemporanea

```

Questa è un'ottima osservazione. Per gestire la complessità di *Confrontation 5*, dove i bonus non sono solo numeri statici (es. "+1 Forza") ma spesso dipendono da fattori contestuali (es. "+1 Forza per ogni ferita subita" o "Forza pari al Rango"), abbiamo bisogno di un sistema flessibile.

In Rails, la soluzione migliore è utilizzare una **Tabella Polimorfica** che chiameremo `StatModifiers`. Questa tabella può essere "agganciata" a qualsiasi modello che fornisce bonus (`Skill`, `Spell`, `Miracle`, `Affiliation`, `Artifact`) e descrivere **come** modificare le statistiche del combattente.

Ecco la soluzione tecnica completa.

### 1. La Migrazione

Creiamo la tabella `stat_modifiers`. Questa tabella funge da "istruzione" per il calcolo delle statistiche.

```bash
rails g model StatModifier \
  source:references{polymorphic} \
  stat_name:string \
  modification_type:integer \
  value_type:integer \
  fixed_value:integer \
  dynamic_value_key:string \
  granted_skill:references \
  condition:string

```

Ora modifichiamo il file di migrazione generato per aggiungere dettagli e vincoli.

```ruby
# db/migrate/[TIMESTAMP]_create_stat_modifiers.rb
class CreateStatModifiers < ActiveRecord::Migration[7.0]
  def change
    create_table :stat_modifiers do |t|
      # Chi fornisce il bonus? (Es. Skill id: 5, Artifact id: 2)
      t.references :source, polymorphic: true, null: false

      # Quale statistica viene modificata? (es. "for_str", "att", "mov_ground")
      # Se nil, è un bonus che non tocca le stat numeriche (es. aggiunge un'abilità)
      t.string :stat_name

      # Che tipo di operazione è? (0: add, 1: subtract, 2: set, 3: grant_skill)
      t.integer :modification_type, default: 0

      # Il valore è fisso o dinamico? (0: fixed, 1: dynamic)
      t.integer :value_type, default: 0

      # Valore fisso (es. +1, -2)
      t.integer :fixed_value

      # Chiave per calcolo dinamico (es. "rank", "size", "wounds_suffered")
      t.string :dynamic_value_key
      
      # Se il bonus conferisce un'abilità (es. "Ottiene Rigenerazione"), colleghiamo l'abilità
      t.references :granted_skill, foreign_key: { to_table: :skills }, null: true

      # Condizioni testuali per l'UI o logica futura (es. "on_charge", "vs_fear")
      t.string :condition

      t.timestamps
    end
  end
end

```

### 2. Aggiornamento dei Modelli

Dobbiamo dire a Rails come interpretare questi dati.

#### Il Modello `StatModifier`

Definiamo gli Enum per rendere il codice leggibile.

```ruby
# app/models/stat_modifier.rb
class StatModifier < ApplicationRecord
  belongs_to :source, polymorphic: true
  belongs_to :granted_skill, class_name: 'Skill', optional: true

  # Tipi di modifica
  enum modification_type: { 
    add: 0,         # Somma al valore base (es. +1 FOR)
    subtract: 1,    # Sottrae (es. -1 MOV)
    set: 2,         # Imposta a un valore fisso (es. FOR diventa 5)
    grant_skill: 3  # Conferisce un'abilità (es. Ottiene "Volo")
  }

  # Tipi di valore
  enum value_type: { 
    fixed: 0,       # Usa il campo fixed_value
    dynamic: 1      # Usa il campo dynamic_value_key
  }
end

```

#### I Modelli "Sorgente" (Provider)

Aggiungiamo la relazione a tutti i modelli che possono dare bonus.

```ruby
# Aggiungi questa riga in: app/models/skill.rb, app/models/spell.rb, 
# app/models/miracle.rb, app/models/artifact.rb, app/models/affiliation.rb

has_many :stat_modifiers, as: :source, dependent: :destroy

```

#### Il Modello `Fighter` (Consumatore)

Qui avviene la magia. Dobbiamo creare un metodo che calcoli le statistiche *effettive* sommando base + modificatori.

```ruby
# app/models/fighter.rb
class Fighter < ApplicationRecord
  # ... associazioni precedenti ...

  # Metodo per calcolare una statistica finale
  def effective_stat(stat_name)
    base_val = self.send(stat_name) || 0
    total_bonus = 0

    # Raccogliamo tutti i modificatori attivi da:
    # 1. Abilità native del guerriero
    # 2. Affiliazione
    # 3. Equipaggiamento (Artefatti) - (Assumendo una relazione has_many :artifacts)
    
    # Esempio semplificato che guarda solo abilità e affiliazioni:
    modifiers = []
    modifiers += skills.flat_map(&:stat_modifiers)
    modifiers += affiliation.stat_modifiers if affiliation.present?
    
    # Filtriamo per la statistica richiesta
    modifiers.select { |m| m.stat_name == stat_name.to_s }.each do |mod|
      
      # Calcola il valore del modificatore
      val = if mod.dynamic?
              calculate_dynamic_value(mod.dynamic_value_key)
            else
              mod.fixed_value
            end

      # Applica l'operazione
      case mod.modification_type
      when 'add' then total_bonus += val
      when 'subtract' then total_bonus -= val
      when 'set' then return val # 'Set' sovrascrive tutto
      end
    end

    return base_val + total_bonus
  end

  private

  # Logica per i valori dinamici (Qui implementi le regole di C5)
  def calculate_dynamic_value(key)
    case key
    when 'rank' then self.rank&.value || 0
    when 'size_power' then self.size&.base_power || 0 # Possanza basata sulla taglia
    when 'wounds_max' then self.size&.base_wounds || 0
    # Aggiungi qui logiche complesse future (es. ferite subite, etc.)
    else 0
    end
  end
end

```

---

### 3. Esempi di Seeding (Come inserire i dati)

Ecco come inseriresti i dati specifici richiesti nel tuo `db/seeds.rb` usando questa nuova struttura.

```ruby
# db/seeds.rb

puts "Creazione Modificatori..."

# ESEMPIO 1: Abilità "Furia Guerriera" (Bonus +1 ATT se tutto in attacco - semplificato +1 ATT)
# [cite_start]Fonte: File 1 [cite: 9526-9530]
furia = Skill.find_by(name: "Furia Guerriera")
StatModifier.create!(
  source: furia,
  stat_name: "att",
  modification_type: :add,
  value_type: :fixed,
  fixed_value: 1,
  condition: "Se tutti i dadi in attacco"
)

# ESEMPIO 2: Affiliazione "Il Massacro" (Divoratori)
# [cite_start]Regola: "+1 COR/PAU" [cite: 7034]
massacro = Affiliation.find_by(name: "Il Massacro")
# Modifica Coraggio
StatModifier.create!(
  source: massacro,
  stat_name: "courage",
  modification_type: :add,
  value_type: :fixed,
  fixed_value: 1
)
# Modifica Paura
StatModifier.create!(
  source: massacro,
  stat_name: "fear",
  modification_type: :add,
  value_type: :fixed,
  fixed_value: 1
)

# ESEMPIO 3: Magia "Forza delle Tenebre"
# [cite_start]Regola: "FOR aumentata di X+1" [cite: 11236]
# Qui X dipende dal mana speso, che è dinamico nel gioco, ma statico come definizione base +1
spell_dark_str = Spell.find_by(name: "Forza delle Tenebre")
StatModifier.create!(
  source: spell_dark_str,
  stat_name: "for_str",
  modification_type: :add,
  value_type: :fixed,
  fixed_value: 1, 
  condition: "+X gemme spese"
)

# ESEMPIO 4: Abilità Dinamica "Colosso" (Inventata per esempio, simile a Taglia)
# Supponiamo un'abilità che dia +1 FOR per ogni punto di Rango
# StatModifier.create!(
#   source: some_skill,
#   stat_name: "for_str",
#   modification_type: :add,
#   value_type: :dynamic,
#   dynamic_value_key: "rank" # Il modello Fighter userà calculate_dynamic_value('rank')
# )

# ESEMPIO 5: Miracolo che conferisce un'Abilità ("Egida di Fervore")
# [cite_start]Regola: "I combattenti ottengono Parata" [cite: 10503]
parata_skill = Skill.find_by(name: "Parata")
miracle_egida = Miracle.find_by(name: "Egida di Fervore")

StatModifier.create!(
  source: miracle_egida,
  modification_type: :grant_skill,
  granted_skill: parata_skill,
  condition: "Aura di Fede"
)

puts "Modificatori applicati!"

```

### Come gestire l'importazione via CSV

Dovrai aggiungere due file CSV per popolare questa logica in massa:

1. **`stat_modifiers.csv`**:
```csv
source_class,source_name,stat_name,modification_type,value_type,fixed_value,dynamic_key,granted_skill_name,condition
Skill,Furia Guerriera,att,add,fixed,1,,,Se tutti dadi in attacco
Affiliation,Il Massacro,courage,add,fixed,1,,,
Affiliation,Il Massacro,fear,add,fixed,1,,,
Miracle,Egida di Fervore,,grant_skill,,,Parata,Aura di Fede
Artifact,Pozione Minore di Forza,for_str,add,fixed,2,,,Fino a fine turno

```

Questa struttura ti permette di coprire quasi tutte le casistiche di *Confrontation 5*, incluse le modifiche temporanee (gestibili nel controller/frontend filtrando i modificatori per "duration") e le modifiche permanenti o di composizione dell'armata.
Questa architettura è molto più solida e orientata a un vero "Army Builder". Separare il **Dato Statico** (Fighter) dall'**Istanza di Gioco** (Profile) è il pattern corretto (simile al pattern *Product* vs *CartItem* negli e-commerce).

Ecco la proposta architetturale completa che elimina gli enum a favore di tabelle di lookup e implementa il sistema di calcolo dinamico.

### 1. Concetto Architetturale

1. **Fighter (Base)**: È il "template". Contiene i dati stampati sulla carta fisica (Statistiche base, Costo base). Non cambia mai.
2. **Profile (Istanza)**: È il soldato che metti in lista. Punta a un `Fighter`. Non ha statistiche proprie, ma metodi che calcolano il totale: `(Fighter.stat + Sum(Modifiers))`.
3. **StatModifier (Definizione)**: È una regola astratta (es. "Bonus Laureken: +1 Costo", "Furia: +1 ATT"). È associata a un'Affiliazione o è Generica.
4. **ProfileModifier (Applicazione)**: È il collegamento tra un `Profile` e uno `StatModifier`. Dice "Questo specifico arciere ha comprato questo specifico bonus".
5. **Lookup Tables**: Sostituiscono gli enum per garantire configurabilità totale (es. `ModificationType`, `StatDefinition`).

---

### 2. Struttura del Database (ERD Logico)

* `fighters` (id, name, army_id, rank_id, size_id, base_stats...)
* `profiles` (id, fighter_id, affiliation_id, custom_name)
* `stat_modifiers` (id, name, affiliation_id[nullable], stat_definition_id, modification_type_id, value)
* `profile_modifiers` (id, profile_id, stat_modifier_id)
* *Tabelle di Lookup*: `ranks`, `sizes`, `stat_definitions`, `modification_types`.

---

### 3. Generatori Rails e Migrazioni

Esegui i comandi in questo ordine.

#### A. Tabelle di Lookup (No Enums)

Queste tabelle definiscono *cosa* misuriamo e *come* lo modifichiamo.

```bash
# Definisce le statistiche modificabili (es. "for_str", "points_cost", "mov_ground")
rails g model StatDefinition code:string label:string description:text

# Definisce l'operazione matematica (es. "add", "set", "remove_skill")
rails g model ModificationType code:string symbol:string description:text

# Le solite tabelle di supporto
rails g model Rank name:string value:integer
rails g model Size name:string base_wounds:integer base_power:integer
rails g model Army name:string

```

#### B. Affiliazioni e Combattenti Base

```bash
rails g model Affiliation name:string army:references description:text

# Il template statico (la carta fisica)
rails g model Fighter name:string title:string \
  army:references rank:references size:references \
  base_cost:integer \
  mov_ground:float mov_fly:float ini:integer att:integer for_str:integer dif:integer res:integer \
  tir:integer courage:integer fear:integer discipline:integer \
  power:integer faith:integer \
  is_unique:boolean

```

#### C. Il Motore di Modifica (StatModifier)

Questo modello contiene la "ricetta" del bonus.

* Se `affiliation_id` è presente, il modificatore è esclusivo di quell'affiliazione (es. Bonus Laureken).
* Se `affiliation_id` è NULL, è un modificatore generico (es. Pozione di Forza).

```bash
rails g model StatModifier name:string description:text \
  affiliation:references \
  stat_definition:references \
  modification_type:references \
  value_integer:integer \
  value_string:string \
  is_mandatory:boolean # Se true, viene applicato automaticamente (es. costo affiliazione)

```

*(Nota: aggiungi `optional: true` alla reference di affiliation nella migration o nel modello)*

#### D. Il Profilo Giocabile (Profile)

Questa è l'istanza che vive nella lista dell'utente.

```bash
rails g model Profile fighter:references affiliation:references custom_name:string

```

#### E. Applicazione dei Modificatori

Collega il profilo ai modificatori scelti.

```bash
rails g model ProfileModifier profile:references stat_modifier:references

```

---

### 4. Logica dei Modelli (Business Logic)

Ecco come implementare il calcolo dinamico.

#### `app/models/fighter.rb`

```ruby
class Fighter < ApplicationRecord
  belongs_to :army
  belongs_to :rank
  belongs_to :size
  has_many :profiles
  
  # Questo metodo serve solo come fallback per il Profile
  def read_stat(stat_code)
    # Mappa i codici delle StatDefinition alle colonne del DB
    # Es. 'cost' -> base_cost, 'att' -> att
    col_name = stat_code == 'cost' ? 'base_cost' : stat_code
    self.send(col_name) || 0
  end
end

```

#### `app/models/profile.rb` (Il Cuore del sistema)

```ruby
class Profile < ApplicationRecord
  belongs_to :fighter
  belongs_to :affiliation, optional: true
  
  has_many :profile_modifiers, dependent: :destroy
  has_many :stat_modifiers, through: :profile_modifiers

  # Callback: Quando creo un profilo, aggiungo i modificatori obbligatori dell'affiliazione
  after_create :apply_mandatory_modifiers

  # Metodo Principale: Calcola il valore finale di una statistica
  def current_value(stat_code)
    # 1. Prendo il valore base dal Fighter
    base = fighter.read_stat(stat_code)
    
    # 2. Cerco tutti i modificatori applicati che impattano questa statistica
    relevant_modifiers = stat_modifiers.includes(:stat_definition, :modification_type)
                                       .where(stat_definitions: { code: stat_code })

    # 3. Applico le modifiche in ordine (Set prima, Add/Sub dopo)
    # Nota: L'ordine è importante. Un 'SET' sovrascrive tutto ciò che c'era prima.
    
    # Eseguiamo prima i SET
    relevant_modifiers.select { |m| m.modification_type.code == 'set' }.each do |mod|
      base = mod.value_integer
    end

    # Eseguiamo Addizioni e Sottrazioni
    relevant_modifiers.select { |m| ['add', 'sub'].include?(m.modification_type.code) }.each do |mod|
      if mod.modification_type.code == 'add'
        base += mod.value_integer
      else
        base -= mod.value_integer
      end
    end

    base
  end

  # Helper per ottenere il costo totale (che è una statistica come le altre nel nostro sistema)
  def total_cost
    current_value('cost')
  end

  private

  def apply_mandatory_modifiers
    return unless affiliation
    
    # Trova modificatori obbligatori dell'affiliazione (es. Costo Laureken)
    affiliation.stat_modifiers.where(is_mandatory: true).each do |mod|
      self.profile_modifiers.create(stat_modifier: mod)
    end
  end
end

```

#### `app/models/stat_modifier.rb`

```ruby
class StatModifier < ApplicationRecord
  belongs_to :affiliation, optional: true # Se nil, è generico/universale
  belongs_to :stat_definition
  belongs_to :modification_type
  
  # Scope per trovare modificatori disponibili per un profilo
  scope :available_for, ->(profile) {
    where(affiliation_id: [nil, profile.affiliation_id])
  }
end

```

---

### 5. File CSV per il Seeding (Esempi Completi)

Questi file popolano le tabelle di lookup e creano lo scenario richiesto (Arciere + Laureken).

#### `stat_definitions.csv`

Definisce cosa possiamo modificare.

```csv
code,label
cost,Costo in Punti
mov,Movimento
att,Attacco
for,Forza
res,Resistenza
skills,Abilità (Speciale)

```

#### `modification_types.csv`

Definisce la matematica.

```csv
code,symbol
add,+
sub,-
set,=
append,Aggiungi (per liste)
remove,Rimuovi (per liste)

```

#### `affiliations.csv`

```csv
name,army_name
Armata di Laureken,Elfi Daikinee

```

#### `stat_modifiers.csv`

Qui definiamo la regola di Laureken (File 9: "Cittadella/Al Servizio del Re" e altri bonus).
*Supponiamo per l'esempio che Laureken aumenti il costo di 1 punto.*

```csv
name,affiliation_name,stat_code,mod_type_code,value_int,is_mandatory
Costo Affiliazione Laureken,Armata di Laureken,cost,add,1,true
Bonus Forza Pozione,null,for,add,2,false

```

#### `fighters.csv`

Il profilo base, pulito.

```csv
name,army_name,rank_name,size_name,base_cost,att,for_str,res
Arciere Daikinee,Elfi Daikinee,Regolare,Media,11,2,3,5

```

---

### 6. Esempio di utilizzo (Console Rails)

Ecco come funziona il sistema una volta importati i dati.

```ruby
# 1. Recupero i dati base
daikinee_army = Army.find_by(name: "Elfi Daikinee")
laureken = Affiliation.find_by(name: "Armata di Laureken")
archer_fighter = Fighter.find_by(name: "Arciere Daikinee")

# L'arciere base ha costo 11
puts archer_fighter.base_cost # => 11

# 2. Creo un PROFILO per la mia lista, affiliato a Laureken
# La callback 'after_create' aggancia automaticamente i modificatori mandatory (il costo extra)
my_archer = Profile.create!(fighter: archer_fighter, affiliation: laureken)

# 3. Verifico il costo
# Fighter Base (11) + Modificatore Laureken (+1) = 12
puts my_archer.total_cost # => 12

# 4. Aggiungo un equipaggiamento opzionale (Pozione di Forza)
potion_mod = StatModifier.find_by(name: "Bonus Forza Pozione")
ProfileModifier.create!(profile: my_archer, stat_modifier: potion_mod)

# 5. Verifico la Forza
# Fighter Base (3) + Pozione (+2) = 5
puts my_archer.current_value('for') # => 5

# 6. Se aggiorno il Fighter base perché esce un'errata (FOR passa a 4)
archer_fighter.update(for_str: 4)

# 7. Il profilo si aggiorna automaticamente
# Fighter Base (4) + Pozione (+2) = 6
puts my_archer.current_value('for') # => 6

```

### Vantaggi di questa struttura

1. **Niente Enum**: Se domani inventano una nuova statistica "Velocità di Nuoto", aggiungi una riga in `StatDefinitions` e sei a posto.
2. **Affiliazioni come Filtri**: Nel controller, quando mostri i potenziamenti disponibili per un profilo, fai semplicemente: `StatModifier.available_for(@profile)`. Questo mostrerà solo i bonus Generici (affiliation_id: nil) E quelli di Laureken, nascondendo quelli delle altre affiliazioni.
3. **Logica Mandatory**: Il flag `is_mandatory` risolve il problema dei costi fissi di affiliazione o dei bonus passivi che si applicano sempre (es. "+1 COR per essere del Massacro").
4. **Override vs Calcolo**: Non sovrascriviamo mai i dati. Se togli la pozione, cancelli il record in `profile_modifiers` e la statistica torna a quella base istantaneamente.

Hai colpito il punto critico di qualsiasi sistema di regole complesso (come D&D o Confrontation). La struttura precedente gestiva bene "1 Modificatore = 1 Statistica", ma per gestire "1 Fonte = Molti Modificatori Condizionali" (il tuo esempio Guerriero vs Mago), dobbiamo fare un piccolo passo evolutivo.

La buona notizia è che **non serve stravolgere tutto**. Dobbiamo solo applicare il concetto di **Requisiti** (che abbiamo creato per gli Artefatti) anche ai **StatModifiers**.

Ecco come perfezionare l'architettura per questo scenario.

### 1. Il Concetto Logico: "Container e Condizioni"

Invece di pensare a un singolo record che fa "tutto", pensiamo alla Fonte (es. una Pozione o un'Affiliazione) come un **Container**.

* **Fonte (Container):** "Benedizione degli Antichi"
* **Modificatore A:** +1 FOR (Attivo **SOLO SE** il bersaglio è Guerriero)
* **Modificatore B:** +1 RES (Attivo **SOLO SE** il bersaglio è Guerriero)
* **Modificatore C:** +1 POT (Attivo **SOLO SE** il bersaglio è Mago)
* **Modificatore D:** Grant Skill 'Concentrazione' (Attivo **SOLO SE** il bersaglio è Mago)



Quando assegni la "Benedizione degli Antichi" a un profilo, il sistema controlla quali dei suoi "figli" (modificatori) si attivano.

### 2. Modifiche al Database

Dobbiamo rendere `StatModifier` un soggetto che può avere dei requisiti (`restrictable`), esattamente come abbiamo fatto per gli Artefatti.

#### A. Migrazione

Dobbiamo assicurarci che la tabella `requirements` possa puntare a `stat_modifiers`. Se hai usato il polimorfismo `restrictable` nella risposta precedente, sei già a posto a livello di DB!

Se non l'hai fatto, o per chiarezza, ecco cosa serve:

```ruby
# Assicurati che StatModifier possa avere requisiti
# Non serve una nuova colonna se Requirements usa il polimorfismo 'restrictable'

```

#### B. Aggiornamento Modelli

**1. `StatModifier.rb**`
Diventa "restricable" (può avere condizioni).

```ruby
class StatModifier < ApplicationRecord
  belongs_to :source, polymorphic: true # Es. Affiliation, Artifact
  has_many :requirements, as: :restrictable, dependent: :destroy

  # Metodo cruciale: il modificatore è attivo per questo profilo?
  def applies_to?(profile)
    # Se non ci sono requisiti, si applica sempre
    return true if requirements.empty?

    # Altrimenti controlla tutti i requisiti contro il fighter del profilo
    requirements.all? do |req|
      req.met_by?(profile.fighter)
    end
  end
end

```

**2. `Requirement.rb**`
Aggiungiamo la logica di controllo (riprendendo quella degli artefatti).

```ruby
class Requirement < ApplicationRecord
  belongs_to :restrictable, polymorphic: true
  
  def met_by?(fighter)
    case check_type
    when 'check_keyword'
      # Esempio: Verifica se il fighter ha la keyword "Mago"
      fighter.keywords.where(name: value_string).exists?
    when 'check_stat'
      # Esempio: Verifica se FOR > 3
      stat_val = fighter.read_stat(value_string) # value_string qui è es. 'for_str'
      stat_val.send(ruby_operator, value_integer)
    # ... altri controlli ...
    end
  end
end

```

**3. `Profile.rb` (Il Calcolatore)**
Aggiorniamo il metodo di calcolo per filtrare i modificatori inattivi.

```ruby
def current_value(stat_code)
  base = fighter.read_stat(stat_code)
  
  # Trova i modificatori collegati tramite le associazioni (es. Affiliazione o Artefatti equipaggiati)
  # Esempio semplificato: prendiamo quelli dell'affiliazione
  
  potential_modifiers = []
  potential_modifiers += affiliation.stat_modifiers if affiliation
  potential_modifiers += profile_modifiers.map(&:stat_modifier) # Modificatori manuali (es. Pozioni)

  # FILTRO CHIAVE: Applica solo se i requisiti sono soddisfatti dal profilo
  active_modifiers = potential_modifiers.select { |mod| mod.applies_to?(self) }

  # Filtra per la statistica richiesta (es. 'for_str')
  relevant_modifiers = active_modifiers.select { |mod| mod.stat_definition.code == stat_code }

  # ... Logica matematica (Add/Set) come prima ...
  relevant_modifiers.each do |mod|
    # applica matematica
  end
  
  base
end

```

### 3. Esempio Pratico (Seed/CSV)

Ecco come rappresentare il tuo esempio: *"Se Guerriero: +1 FOR/RES. Se Mago: +1 POT, Skill Concentrazione"*.
Supponiamo che la fonte sia un'Affiliazione chiamata "Ordine del Drago".

**Passo 1: Creazione dei Modificatori (StatModifier)**

Nel CSV `stat_modifiers.csv`, creiamo 4 righe separate che puntano alla stessa fonte.

```csv
name,source_type,source_name,stat_code,mod_type,value_int,granted_skill
Bonus Guerriero FOR,Affiliation,Ordine del Drago,for_str,add,1,
Bonus Guerriero RES,Affiliation,Ordine del Drago,res,add,1,
Bonus Mago POT,Affiliation,Ordine del Drago,power,add,1,
Bonus Mago Skill,Affiliation,Ordine del Drago,,grant_skill,,Concentrazione

```

**Passo 2: Creazione dei Requisiti (Requirement)**

Nel CSV `requirements.csv`, attacchiamo le condizioni ai modificatori specifici.
*(Nota: Qui uso il nome del modificatore come chiave per l'importazione, nella realtà useresti un ID o una logica di associazione nello script di seed)*.

```csv
target_class,target_name,check_type,value_string,operator
StatModifier,Bonus Guerriero FOR,check_keyword,Guerriero,eq
StatModifier,Bonus Guerriero RES,check_keyword,Guerriero,eq
StatModifier,Bonus Mago POT,check_keyword,Mago,eq
StatModifier,Bonus Mago Skill,check_keyword,Mago,eq

```

### 4. Come funziona in gioco

1. Crei un profilo per **Kassar** (Keyword: *Guerriero*) e gli dai l'affiliazione "Ordine del Drago".
2. L'applicazione carica i 4 modificatori dell'affiliazione.
3. Per ogni modificatore, chiama `applies_to?(Kassar)`:
* *Bonus Guerriero FOR*: Kassar ha la keyword "Guerriero"? **Sì**. -> **Attivo**.
* *Bonus Mago POT*: Kassar ha la keyword "Mago"? **No**. -> **Ignorato**.


4. Risultato: Kassar ottiene +1 FOR e +1 RES, ma niente POT.

### Vantaggi di questo approccio

1. **Atomicità**: Ogni bonus è un piccolo "mattoncino" logico. È facilissimo da debuggare.
2. **Riutilizzabilità**: La logica dei `Requirement` è la stessa usata per vedere se *puoi* equipaggiare un oggetto. Qui la usiamo per vedere se l'oggetto *funziona*.
3. **Scalabilità**: Se domani esce un'abilità che dice "Se hai meno di 2 ferite, +2 DIF", puoi modellarla:
* `StatModifier`: +2 DIF
* `Requirement`: check_stat "wounds", operator "lt", value 2.
* Il sistema ricalcolerà dinamicamente il valore ogni volta che aggiorni le ferite del profilo.
Con queste modifiche, il tuo sistema di gestione delle regole diventa estremamente flessibile e potente, capace di adattarsi a qualsiasi nuova esigenza di gioco senza dover riscrivere codice o migrare dati.

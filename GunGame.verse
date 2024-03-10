using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath}

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
GunGame := class(creative_device):
    
    var PlayerMap : [player]int = map {}
    var KillStreakDictionary : [agent]int = map{}
    @editable
    var KillStreakGranter : item_granter_device = item_granter_device{}
    @editable
    var EndGameDevice : end_game_device = end_game_device{}
    @editable
    var KillStreakCheckers : []conditional_button_device = array{}
    @editable
    var ElimsToEndGame : int = 0
    KillStreakerNums : []int = array{1,5,7,10}
    @editable
    var TestGranter : item_granter_device = item_granter_device{}
    @editable
    var KillStreakHUD : []hud_message_device = array{}
    @editable 
    var Sentries : []sentry_device = array{}
    @editable
    var HudDevice : hud_message_device = hud_message_device{}
    KillStreakNumber<localizes>(String : string) : message = "{String}"
    var MakeSureItemsAreGranted : string = ""

    OnBegin<override>()<suspends>:void=
        InitPlayers()
        InitTestMode()
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)

    InitPlayers() : void= 
        AllPlayers := GetPlayspace().GetPlayers()
        # Initiate all player maps
        for (Player : AllPlayers, FortCharacter := Player.GetFortCharacter[]):
            TestGranter.GrantItem(Player)
            # Okay this might look very complicated but its just mapping 
            if (set PlayerMap[Player] = 0, WeaponTier := PlayerMap[Player],NewAgent := Player.GetFortCharacter[],
            NewerAgent := NewAgent.GetAgent[], set KillStreakDictionary[NewerAgent] = 0):
                for(Key->Values:PlayerMap){
                    Print("User is the key and this it is paired to {Values}")
                }
                spawn:
                    UpdateUI(Player)
                FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminated)
                if(AgentToBeGranted := FortCharacter.GetAgent[])  {
                GrantWeapon(AgentToBeGranted, WeaponTier)
                }

    OnPlayerAdded(Player:player):void=
        if:
            FortCharacter := Player.GetFortCharacter[]
            set PlayerMap[Player] = 0
            WeaponTier := PlayerMap[Player]
        then:
            FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminated)
            GrantWeapon(Player, WeaponTier)

    GrantWeapon(Agent : agent, WeaponTier : int) : void=
            TestGranter.SetNextItem(WeaponTier)
            TestGranter.GrantItem(Agent)

    OnPlayerEliminated(Result : elimination_result): void=
        Eliminator := Result.EliminatingCharacter
        if (FortCharacter := Result.EliminatingCharacter?,
         EliminatingAgent := FortCharacter.GetAgent[],EliminatedAgent := Result.EliminatedCharacter.GetAgent[]):
            if(set KillStreakDictionary[EliminatingAgent] += 1,set KillStreakDictionary[EliminatedAgent] = 0){
                KillStreakChecker(EliminatingAgent)
            }
            PromotePlayer(EliminatingAgent)

    PromotePlayer(Agent : agent) : void=
        var WeaponTier : int = 0
        if (Player := player[Agent], PlayerWeaponTier := PlayerMap[Player]):
            set WeaponTier = PlayerWeaponTier + 1
            CheckEndGame(Agent, WeaponTier)
        if (Player := player[Agent], set PlayerMap[Player] = WeaponTier):
            spawn:
                UpdateUI(Agent)
            GrantWeapon(Player, WeaponTier)

    KillStreakChecker(Agent : agent):void=
        var FirstTime : logic = false
        var StoredX : int = 0
        if (Streak := KillStreakDictionary[Agent]){
            for(x : KillStreakerNums){
                if(Streak >= x):
                    set StoredX = x
                if(Streak = x){
                    set FirstTime = true
                }
            }
        }   
        if(Alert := KillStreakerNums.Find[StoredX]){
            spawn{KillStreakUI(Agent,FirstTime,Alert)}
        }
        if( NewStored := KillStreakerNums.Find[StoredX],Checker := KillStreakCheckers[NewStored]){
            Check := Checker.GetItemCount(Agent,NewStored)
            # This if statement may be removed once epic resolves the bug
            if(Verify := Checker.HasAllItems[Agent]){ 
                set FirstTime = true
            }
            if:
                Check <> 0 or FirstTime?
            then:
                KillStreakGranter.SetNextItem(NewStored)
                KillStreakGranter.GrantItem(Agent)
            
        }
        
        
    InitTestMode() : void=
        for (Sentry : Sentries):
            Sentry.EliminatedEvent.Subscribe(TestPlayerElimination)

    TestPlayerElimination(Agent : ?agent) : void=
       if (Player := Agent?):
            if(set KillStreakDictionary[Player] += 1,TestVal := KillStreakDictionary[Player]){
                Print(ToString(TestVal))
                KillStreakChecker(Player)
            }
            spawn:
                UpdateUI(Player)
            PromotePlayer(Player)


    CheckEndGame(Player : agent, WeaponTier : int) : void=
        if (WeaponTier >= ElimsToEndGame):
            EndGameDevice.Activate(Player)
    UpdateUI(Agent : agent)<suspends>:void=
        if(Message := KillStreakDictionary[Agent]){
            HudDevice.SetText(KillStreakNumber(ToString(Message)))
            HudDevice.Show(Agent)
        }
    KillStreakUI(Agent : agent, ShouldShow : logic, index : int)<suspends>:void=
        if(Alert := KillStreakHUD[index],ShouldShow?){
            Alert.Show(Agent)
            Sleep(4.0)
            KillStreakGranter.GrantItem(Agent)
        }
        
    


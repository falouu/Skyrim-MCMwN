Scriptname CustomMapMarkersInitScript extends Quest  
{Starts Custom Map Markers with Notes mod}

; /* version - updating
Float fVersion;

; /* constants */
Float interval = 2.0
String mapMenuName = "MapMenu"

; /* STRINGS TO TRANSLATION */
string sErrorAddingSpell
string sMessageNoMarkersAvailable
string sMessageCannotMarkInside
string sMessageLocationMarked
string sMessageModStarting
string sMessageModUpdated
string sMessageModCannotBeUpdated

; /* registered SKSE events */
string sMarkerRemoveEvent = "MCMwN_markerRemove"
string sMarkerChangeNoteEvent = "MCMwN_markerChangeNote"

; /* private variables */
;array where index is marker number and value is marker note
String[] markersNotes
;array where index is marker number and value is marker state (0 - unused; 1 - used; 2 - unused but need to move)
int[] markersState ;default int value = 0

; /* properties */
Spell           property MCMwNmakeMarker            auto
FormList        property MCMwNmarkersFormList       auto
ObjectReference property MCMwNstorageLocationMarker auto

Event OnInit()
	markersNotes = new String[128]
	markersState = new int[128]
	RegisterForSingleUpdate(interval) ; Give us a single update in one second
	RegisterForMenuEvents()
	RegisterForMenu(mapMenuName)
	LocalizeStrings()
	Debug.Notification(sMessageModStarting)
	;set version
	fVersion = 0.2
EndEvent

; must be called once per every savegame load
Function OnGameLoaded()
	LocalizeStrings()
	FixRemovedMarkers()
	; updating scripts
	if(fVersion < 0.2)
		fVersion = 0.2
		Debug.MessageBox(sMessageModCannotBeUpdated)
	endIf
	RegisterForMenuEvents()
EndFunction


Function RegisterForMenuEvents()
	RegisterForModEvent(sMarkerRemoveEvent, "OnMarkerRemove")
	RegisterForModEvent(sMarkerChangeNoteEvent, "OnMarkerChangeNote")
EndFunction

; set strings values according to game languange
Function LocalizeStrings()
	if (Utility.GetINIString("sLanguage:General") == "POLISH")
		sErrorAddingSpell = "MCMwN - BŁĄD: nie powiodło się dodanie czaru 'Oznacz lokację'!"
		sMessageNoMarkersAvailable = "Nie masz wolnych znaczników. Usuń najpierw jeden z nich z mapy."
		sMessageCannotMarkInside = "Nie można oznaczyć lokacji będąc we wnętrzu"
		sMessageLocationMarked = "Oznaczono lokację na mapie"
		sMessageModStarting = "mod \"Multiple Custom Markers with Notes\" został uruchomiony."
		sMessageModUpdated = "mod 'Multiple Custom Markers with Notes' został zaktualizowany."
		sMessageModCannotBeUpdated = "mod 'Multiple Custom Markers with Notes' nie może zostać zaktualizowany z wersji 0.1. Wyłącz mod, zapisz grę i ponownie włącz mod."
	else 
		sErrorAddingSpell = "MCMwN - ERROR: adding spell 'Mark Location' failed!"
		sMessageNoMarkersAvailable = "You have no markers available. Remove one of your markers first."
		sMessageCannotMarkInside = "Cannot mark location in interiors."
		sMessageLocationMarked = "Location has been marked on the map."
		sMessageModStarting = "Multiple Custom Markers with Notes mod started."
		sMessageModUpdated = "Multiple Custom Markers with Notes mod updated."
		sMessageModCannotBeUpdated = "Multiple Custom Markers with Notes mod cannot be updated from version 0.1. Disable mod, save game, and enable mod again."
	endIf
EndFunction

; do nothing unless in readyState
Function MarkPlayerLocation()
EndFunction

; do nothing unless in readyState
Event OnMarkerRemove(string eventName, string strArg, float numArg, Form sender)
EndEvent

; do nothing unless in readyState
Event OnMarkerChangeNote(string eventName, string strArg, float numArg, Form sender)
EndEvent

; wait for ready state
Function FixRemovedMarkers()
	Utility.WaitMenuMode(0.5) 
	FixRemovedMarkers()
EndFunction

;on menu close we have to move removed markers to player position
Event OnMenuClose(String MenuName)
	FixRemovedMarkers()
EndEvent

int Function GetFirstUnusedMarkerIndex()
	int i=0
	int len = markersState.length
	int objCount = MCMwNmarkersFormList.getSize()
	if (objCount < len)
		len = objCount
	endIf
	while (i < len && markersState[i])
		i += 1
	endWhile
	if (i == len)
		return -1
	endIf
	return i
EndFunction

Auto State readyState
	Event OnUpdate()
		if (!Game.GetPlayer().AddSpell(MCMwNmakeMarker))
			Debug.Notification(sErrorAddingSpell)
		endIf
	EndEvent

	; /* map menu open event */
	Event OnMenuOpen(String MenuName)
		UI.InvokeStringA(mapMenuName, "_global.Map.MapMenu.setCustomMarkersData", markersNotes)
	EndEvent

	; /* event dispatched by map menu */
	; numArg - marker index
	Event OnMarkerRemove(string eventName, string strArg, float numArg, Form sender)
		gotoState("lockState")
		int mIndex = numArg as int
		; move marker back to the marker storage location
		ObjectReference marker = MCMwNmarkersFormList.getAt(mIndex - 1) as ObjectReference
		marker.Disable();
		marker.MoveTo( MCMwNstorageLocationMarker ) 
		; set marker removed
		markersState[mIndex - 1] = 2 ;"need to move to player position" state
		gotoState("readyState")
	EndEvent

	; /* event dispatched by map menu */
	; strArg - new note
	; numArg - marker index
	Event OnMarkerChangeNote(string eventName, string strArg, float numArg, Form sender)
		gotoState("lockState")
		int mIndex = numArg as int
		;Debug.Notification("MCMwN - Debug: change note of location "+mIndex+" to: "+strArg)
		markersNotes[mIndex - 1] = strArg
		gotoState("readyState")
	EndEvent

	; move available marker to player location
	Function MarkPlayerLocation()
		gotoState("lockState")
		;player is in interior - cannot mark
		if (Game.GetPlayer().IsInInterior())
			Debug.Notification(sMessageCannotMarkInside)
			gotoState("readyState")
			return
		endIf
		
		int uMIndex = GetFirstUnusedMarkerIndex()
		if (uMIndex == -1)
			Debug.MessageBox(sMessageNoMarkersAvailable)
			;Debug.MessageBox("$MCMwN_NO_MARKERS_AVAILABLE")
			gotoState("readyState")
			return
		endIf
		ObjectReference marker = MCMwNmarkersFormList.getAt(uMIndex) as ObjectReference
		marker.MoveTo(Game.GetPlayer())
		marker.Enable()
		markersState[uMIndex] = 1 ; "used" state
		markersNotes[uMIndex] = ""
		Debug.Notification(sMessageLocationMarked)
		gotoState("readyState")
	EndFunction
	
	; move removed markers to player position (fixing save/load issue)
	Function FixRemovedMarkers()
		gotoState("lockState")
		int i=0
		int len = markersState.length
		int objCount = MCMwNmarkersFormList.getSize()
		if (objCount < len)
			len = objCount
		endIf
		while (i < len)
			if (markersState[i] == 2) 
				ObjectReference marker = MCMwNmarkersFormList.getAt(i) as ObjectReference
				marker.MoveTo(Game.GetPlayer())
				markersState[i] = 0
			endIf
			i += 1
		endWhile
		gotoState("readyState")
	EndFunction
EndState

State lockState
	;functions are locked for thread safety
EndState
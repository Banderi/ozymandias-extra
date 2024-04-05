extends Node

signal freeing_orphans

func free_orphaned_nodes():
	print("freeing...")
	emit_signal("freeing_orphans")
	print("done!")

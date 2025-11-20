class_name ComponentCreationManager
extends Node

var main: Node2D

func _init(main_node: Node2D):
	main = main_node
	print("ComponentCreationManager instantiated.")

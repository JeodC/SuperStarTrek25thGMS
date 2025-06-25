/// @obj_ui_button_Create
/// @description: Instances of buttons that change their text dynamically

pressed = false;
hovered = false;
is_selected = false;
text = "";
can_continue = true;
continue_color = can_continue ? c_yellow : c_grey;

// Override self in specific cases
if (!variable_instance_exists(id, "menu_id")) {
  menu_id = "unknown";
}
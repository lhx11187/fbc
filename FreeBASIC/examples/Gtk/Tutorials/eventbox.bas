' Eventbox.bas
' Translated from C to FB by TinyCla, 2006

Option Explicit
Option Escape

#include once "gtk/gtk.bi"

#define NULL 0

' ==============================================
' Main
' ==============================================

	Dim As GtkWidget Ptr win
	Dim As GtkWidget Ptr event_box
	Dim As GtkWidget Ptr label
	
	gtk_init (NULL, NULL)
	
	win = gtk_window_new (GTK_WINDOW_TOPLEVEL)
	
	gtk_window_set_title (GTK_WINDOW (win), "Event Box")
	
	g_signal_connect (G_OBJECT (win), "destroy", G_CALLBACK (@gtk_main_quit), NULL)
	
	gtk_container_set_border_width (GTK_CONTAINER (win), 10)
	
	' Create an EventBox and add it to our toplevel window
	
	event_box = gtk_event_box_new ()
	gtk_container_add (GTK_CONTAINER (win), event_box)
	gtk_widget_show (event_box)
	
	' Create a long label
	
	label = gtk_label_new ("Click here to quit, quit, quit, quit, quit")
	gtk_container_add (GTK_CONTAINER (event_box), label)
	gtk_widget_show (label)
	
	' Clip it short.
	gtk_widget_set_size_request (label, 110, 20)
	
	' And bind an action to it 
	gtk_widget_set_events (event_box, GDK_BUTTON_PRESS_MASK)
	g_signal_connect (G_OBJECT (event_box), "button_press_event", G_CALLBACK (@gtk_main_quit), NULL)
	
	' Yet one more thing you need an X window for ...
	gtk_widget_realize (event_box)
	gdk_window_set_cursor (event_box->Window, gdk_cursor_new (GDK_HAND1))
	
	gtk_widget_show (win)
	
	gtk_main ()

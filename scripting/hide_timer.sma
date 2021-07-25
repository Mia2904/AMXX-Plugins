#include <amxmodx>
#include <fakemeta>

#define HIDE_TIMER    (1<<4)
#define HIDE_MONEY    (1<<5)

new gmsgHideWeapon, gmsgCrosshair
new g_iClientCommand

public plugin_init()
{
    register_plugin( "Hide Timer", "0.1", "Mia2904" )

    register_event("ResetHUD", "Event_ResetHUD", "b")
    register_message((gmsgHideWeapon = get_user_msgid("HideWeapon")), "Message_HideWeapon")
    gmsgCrosshair = get_user_msgid("Crosshair")

    set_msg_block(get_user_msgid("RoundTime"), BLOCK_SET)
}

public Message_HideWeapon(iMsgId, MSG_DEST, id)
{
    new iFlags = get_msg_arg_int(1)
    if(!(iFlags & HIDE_TIMER))
        iFlags |= HIDE_TIMER
/*    if(!(iFlags & HIDE_MONEY))
        iFlags |= HIDE_MONEY    */
    set_msg_arg_int(1, ARG_BYTE, iFlags)
}

public Event_ResetHUD(id)
{
    static const szClientCommand[] = "ClientCommand"
    g_iClientCommand = register_forward(FM_ClientCommand, szClientCommand, 1)
}

public ClientCommand(id)
{
    unregister_forward(FM_ClientCommand, g_iClientCommand)

    message_begin(MSG_ONE_UNRELIABLE, gmsgHideWeapon, _, id)
    write_byte(HIDE_TIMER/*|HIDE_MONEY*/)
    message_end()

    message_begin(MSG_ONE_UNRELIABLE, gmsgCrosshair, _, id)
    write_byte(0)
    message_end()
} 
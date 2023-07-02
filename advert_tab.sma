#include < amxmodx >

new MsgServerName, oMessage = -1;
new szText[][] = {                   //Текст рекламок
	"We Love Gaming", 
	"WLG Classic 1.6", 
	"We Love Georgia"
};

#define TASK 82918                  //Не изменять или изменять - Ваше право.
#define FREQ 2.5                  //Переключение рекламы в секундах
#define RANDOM                  //Чтобы реклама была рандомной - разкоментируйте. (Рекомендуется, чтобы было от 3-х сообщений в массиве)

public plugin_init() {
	register_plugin( "Avert Tab", "1.1", "PAffAEJIkA :3" );
	
	MsgServerName   = get_user_msgid("ServerName");
	set_task(FREQ, "UPD_Tab", TASK, .flags = "b");
}

public UPD_Tab(){   
	#if defined RANDOM
	
	new iRandom = random_num(0, charsmax(szText));
	
	if(oMessage == iRandom)
		iRandom = iRandom == charsmax(szText) ? 0 : ++ iRandom;
	
	oMessage = iRandom;
	#else
	oMessage = oMessage == charsmax(szText) ? 0 : ++ oMessage;
	#endif
	
	message_begin(MSG_BROADCAST, MsgServerName);
	write_string(szText[oMessage]);
	message_end();   
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

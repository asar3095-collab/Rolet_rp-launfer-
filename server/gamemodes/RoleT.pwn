#include <a_samp>

#define DIALOG_REGISTER 1000
#define DIALOG_LOGIN    1001

enum E_PLAYER_DATA
{
    bool:pLoggedIn,
    pPasswordSalt[16],
    pPasswordHash[65],
    pMoney,
    pLevel
};
new PlayerData[MAX_PLAYERS][E_PLAYER_DATA];

stock GetAccountPath(playerid, path[], size)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
    format(path, size, "RoleT_%s.ini", name);
    return 1;
}

stock ShowAccountDialog(playerid)
{
    new path[64], message[144];
    GetAccountPath(playerid, path, sizeof path);
    if (fexist(path))
    {
        format(message, sizeof message, "Добро пожаловать на RoleT RP, %s!\nВведи пароль от аккаунта:", GetPlayerNameEx(playerid));
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "RoleT RP | Авторизация", message, "Войти", "Выход");
    }
    else
    {
        format(message, sizeof message, "Привет, %s!\nАккаунт ещё не создан. Придумай пароль:", GetPlayerNameEx(playerid));
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "RoleT RP | Регистрация", message, "Создать", "Выход");
    }
    return 1;
}

stock GetPlayerNameEx(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
    return name[0];
}

stock SaveAccount(playerid)
{
    if (!PlayerData[playerid][pLoggedIn]) return 0;

    new path[64], line[128], File:file;
    GetAccountPath(playerid, path, sizeof path);
    file = fopen(path, io_write);
    if (!file) return 0;

    format(line, sizeof line, "%s\r\n", PlayerData[playerid][pPasswordSalt]);
    fwrite(file, line);
    format(line, sizeof line, "%s\r\n", PlayerData[playerid][pPasswordHash]);
    fwrite(file, line);
    format(line, sizeof line, "%d\r\n%d\r\n", PlayerData[playerid][pMoney], PlayerData[playerid][pLevel]);
    fwrite(file, line);
    fclose(file);
    return 1;
}

stock LoadAccount(playerid)
{
    new path[64], line[128], File:file;
    GetAccountPath(playerid, path, sizeof path);
    file = fopen(path, io_read);
    if (!file) return 0;

    fread(file, PlayerData[playerid][pPasswordSalt]);
    fread(file, PlayerData[playerid][pPasswordHash]);
    fread(file, line);
    PlayerData[playerid][pMoney] = strval(line);
    fread(file, line);
    PlayerData[playerid][pLevel] = strval(line);
    fclose(file);
    return 1;
}

public OnGameModeInit()
{
    SetGameModeText("RoleT RP | Alpha");
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    ShowNameTags(1);
    AllowInteriorWeapons(1);
    UsePlayerPedAnims();
    AddPlayerClass(0, 1481.0, -1771.0, 18.8, 90.0, 0, 0, 0, 0, 0, 0);
    print("------------------------------------");
    print(" RoleT RP: базовый игровой режим запущен");
    print("------------------------------------");
    return 1;
}

public OnGameModeExit()
{
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i)) SaveAccount(i);
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerData[playerid][pLoggedIn] = false;
    PlayerData[playerid][pMoney] = 5000;
    PlayerData[playerid][pLevel] = 1;
    SendClientMessage(playerid, 0xEFC46BFF, "Добро пожаловать на RoleT RP!");
    SendClientMessage(playerid, 0xFFFFFFFF, "Для игры необходимо войти или создать аккаунт.");
    ShowAccountDialog(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason
    SaveAccount(playerid);
    PlayerData[playerid][pLoggedIn] = false;
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused listitem
    if (!response)
    {
        Kick(playerid);
        return 1;
    }

    if (dialogid == DIALOG_REGISTER)
    {
        if (strlen(inputtext) < 6 || strlen(inputtext) > 32)
        {
            ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,
                "RoleT RP | Регистрация", "Пароль должен содержать от 6 до 32 символов.\nПопробуй ещё раз:", "Создать", "Выход");
            return 1;
        }

        new salt[16], hash[65];
        format(salt, sizeof salt, "%06d", random(899999) + 100000);
        SHA256_PassHash(inputtext, salt, hash, sizeof hash);
        format(PlayerData[playerid][pPasswordSalt], 16, "%s", salt);
        format(PlayerData[playerid][pPasswordHash], 65, "%s", hash);
        PlayerData[playerid][pMoney] = 5000;
        PlayerData[playerid][pLevel] = 1;
        PlayerData[playerid][pLoggedIn] = true;
        SaveAccount(playerid);
        GivePlayerMoney(playerid, PlayerData[playerid][pMoney]);
        SetSpawnInfo(playerid, 0, 0, 1481.0, -1771.0, 18.8, 90.0, 0, 0, 0, 0, 0, 0);
        SpawnPlayer(playerid);
        SendClientMessage(playerid, 0x75D49AFF, "Аккаунт RoleT RP успешно создан! Приятной игры.");
        return 1;
    }

    if (dialogid == DIALOG_LOGIN)
    {
        if (strlen(inputtext) < 1)
        {
            ShowAccountDialog(playerid);
            return 1;
        }
        LoadAccount(playerid);
        new hash[65];
        SHA256_PassHash(inputtext, PlayerData[playerid][pPasswordSalt], hash, sizeof hash);
        if (strcmp(hash, PlayerData[playerid][pPasswordHash], false) != 0)
        {
            ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,
                "RoleT RP | Ошибка", "Неверный пароль.\nПопробуй ещё раз:", "Войти", "Выход");
            return 1;
        }

        PlayerData[playerid][pLoggedIn] = true;
        ResetPlayerMoney(playerid);
        GivePlayerMoney(playerid, PlayerData[playerid][pMoney]);
        SetSpawnInfo(playerid, 0, 0, 1481.0, -1771.0, 18.8, 90.0, 0, 0, 0, 0, 0, 0);
        SpawnPlayer(playerid);
        SendClientMessage(playerid, 0x75D49AFF, "Ты успешно авторизовался на RoleT RP!");
        return 1;
    }
    return 0;
}

public OnPlayerSpawn(playerid)
{
    if (!PlayerData[playerid][pLoggedIn])
    {
        TogglePlayerControllable(playerid, 0);
        return 1;
    }
    TogglePlayerControllable(playerid, 1);
    SetPlayerSkin(playerid, 26);
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!PlayerData[playerid][pLoggedIn])
        return SendClientMessage(playerid, 0xFF7777FF, "Сначала войди в аккаунт.");

    if (!strcmp(cmdtext, "/stats", true))
    {
        new text[144];
        format(text, sizeof text, "Уровень: %d | Деньги: $%d", PlayerData[playerid][pLevel], PlayerData[playerid][pMoney]);
        SendClientMessage(playerid, 0xEFC46BFF, text);
        return 1;
    }
    if (!strcmp(cmdtext, "/help", true))
    {
        SendClientMessage(playerid, 0xEFC46BFF, "RoleT RP | Команды: /stats, /help");
        return 1;
    }
    return 0;
}

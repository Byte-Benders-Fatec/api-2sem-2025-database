@echo off
:: Script para resetar, criar e popular o banco de dados MySQL

:: Carregar as variáveis do arquivo .env
for /f "tokens=1,2 delims==" %%A in (.env) do (
    set %%A=%%B
)

:: Exibe as variáveis carregadas
echo.
echo ========================
echo  Variaveis carregada
echo ========================
echo DB_HOST=%DB_HOST%
echo DB_PORT=%DB_PORT%
echo DB_NAME=%DB_NAME%
echo DB_USER=%DB_USER%
echo MYSQL_BIN=%MYSQL_BIN%
echo RESET=%RESET%
echo SCHEMA=%SCHEMA%
echo TRIGGERS=%TRIGGERS%
echo SEED=%SEED%

:: Solicita a senha MySQL, caso não tenha sido definida no .env
if "%DB_PASSWORD%"=="" set /p DB_PASSWORD="Digite a senha MySQL: "

echo.
echo ========================
echo Executando reset do banco
echo ========================
%MYSQL_BIN% -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASSWORD% < %RESET%

echo.
echo ========================
echo Criando schema
echo ========================
%MYSQL_BIN% -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASSWORD% < %SCHEMA%

echo.
echo ========================
echo Criando triggers
echo ========================
%MYSQL_BIN% -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASSWORD% < %TRIGGERS%

echo.
echo ========================
echo Inserindo dados (seed)
echo ========================
%MYSQL_BIN% -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASSWORD% < %SEED%

echo.
echo ========================
echo Concluido!
echo ========================

:: Verifica se o script foi chamado no terminal ou por duplo clique
if not defined CMDCMDLINE (
    pause
)

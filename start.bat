@echo off
echo Starting Kohza Platform...
echo.
echo Installing dependencies...
call npm install
echo.
echo Starting development servers...
echo - Vite dev server: http://localhost:5173
echo - Mux proxy server: http://localhost:3001
echo.
call npm start
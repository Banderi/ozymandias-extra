#include "Memory.hpp"

int Memory::GetProcessId(char* processName) {
    SetLastError(0);
    PROCESSENTRY32 pe32;
    HANDLE hSnapshot = NULL;
    GetLastError();
    pe32.dwSize = sizeof( PROCESSENTRY32 );
    hSnapshot = CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );
    
    if( Process32First( hSnapshot, &pe32 ) ) {
        do {
            if( strcmp( pe32.szExeFile, processName ) == 0 )
                break;
        } while( Process32Next( hSnapshot, &pe32 ) );
    }
    
    if( hSnapshot != INVALID_HANDLE_VALUE )
        CloseHandle( hSnapshot );
    int err = GetLastError();
    if (err != 0) {
        lastError = err;
        return -1;
    }
    lastError = 0;
    return pe32.th32ProcessID;
}
int Memory::GetModuleBase(HANDLE processHandle, std::basic_string<char> sModuleName)
{ 
    HMODULE *hModules = NULL; 
    char szBuf[50]; 
    DWORD cModules;
    unsigned long long dwBase = -1;

    EnumProcessModulesEx(processHandle, hModules, 0, &cModules, LIST_MODULES_ALL);
    hModules = new HMODULE[cModules/sizeof(HMODULE)]; 
    
    if(EnumProcessModulesEx(processHandle, hModules, cModules/sizeof(HMODULE), &cModules, LIST_MODULES_ALL)) {
       for(size_t i = 0; i < cModules/sizeof(HMODULE); i++) { 
          if(GetModuleBaseName(processHandle, hModules[i], szBuf, sizeof(szBuf))) { 
             if(sModuleName.compare(szBuf) == 0) { 
                dwBase = (unsigned long long)hModules[i];
                break; 
             } 
          } 
       } 
    } 
    
    delete[] hModules;
    return dwBase; 
}
BOOL Memory::SetPrivilege(HANDLE hToken, LPCTSTR lpszPrivilege, BOOL bEnablePrivilege)
{
    TOKEN_PRIVILEGES tp;
    LUID luid;

    if (!LookupPrivilegeValue(NULL, lpszPrivilege, &luid)) {
        lastError = GetLastError();
        return FALSE;
    }

    tp.PrivilegeCount = 1;
    tp.Privileges[0].Luid = luid;
    if (bEnablePrivilege)
        tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
    else
        tp.Privileges[0].Attributes = 0;

    if (!AdjustTokenPrivileges(hToken, FALSE, &tp, sizeof(TOKEN_PRIVILEGES), (PTOKEN_PRIVILEGES) NULL, (PDWORD) NULL)) {
        lastError = GetLastError();
        return FALSE;
    }

    if (GetLastError() == ERROR_NOT_ALL_ASSIGNED) {
        lastError = GetLastError();
        return FALSE;
    }
    lastError = 0;
    return TRUE;
}
BOOL Memory::GetDebugPrivileges(void) {
	HANDLE hToken = NULL;
    if(!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, &hToken)) {
        lastError = GetLastError();
        return FALSE;
    }
    if(!SetPrivilege(hToken, SE_DEBUG_NAME, TRUE)) {
        lastError = GetLastError();
        return FALSE;
    }
    lastError = 0;
	return TRUE;
}
int64_t Memory::Read(HANDLE processHandle, int address, SIZE_T NumberOfBytesToRead) {
    if (address == -1) {
        lastError = -1;
        return -1;
    }
    int64_t buffer = 0;
    SIZE_T NumberOfBytesActuallyRead;
    BOOL success = ReadProcessMemory(processHandle, (LPCVOID)address, &buffer, NumberOfBytesToRead, &NumberOfBytesActuallyRead);
    if (!success || NumberOfBytesActuallyRead != NumberOfBytesToRead) {
        lastError = GetLastError();
        return -1;
    }
//    if (err || NumberOfBytesActuallyRead != NumberOfBytesToRead) {
//		DWORD lastError = GetLastError();
//		if (lastError != 0)
//            std::cout << lastError << std::endl;
//        std::cout << "blub" << std::endl;
//	}
    lastError = 0;
    return buffer; 
}
int Memory::GetPointerAddress(HANDLE processHandle, int startAddress, int offsets[], int offsetCount) {
    if (startAddress == -1) {
        lastError = -1;
        return -1;
    }
	int ptr = Read(processHandle, startAddress, 4);
	for (int i=0; i<offsetCount-1; i++) {
		ptr+=offsets[i];
		ptr = Read(processHandle, ptr, 4);
	}
	ptr+=offsets[offsetCount-1];
	return ptr;
}
int Memory::ReadPointerInt(HANDLE processHandle, int startAddress, int offsets[], int offsetCount) {
    if (startAddress == -1) {
        lastError = -1;
        return -1;
    }
	return Read(processHandle, GetPointerAddress(processHandle, startAddress, offsets, offsetCount), 4);
}
float Memory::ReadFloat(HANDLE processHandle, int address) {
    if (address == -1) {
        lastError = -1;
        return -1;
    }
    float buffer = 0.0;
    SIZE_T NumberOfBytesToRead = sizeof(buffer); //this is equal to 4
    SIZE_T NumberOfBytesActuallyRead;
    BOOL success = ReadProcessMemory(processHandle, (LPCVOID)address, &buffer, NumberOfBytesToRead, &NumberOfBytesActuallyRead);
    if (!success || NumberOfBytesActuallyRead != NumberOfBytesToRead) {
        lastError = -1;
        return -1;
    }
    lastError = 0;
    return buffer; 
}
float Memory::ReadPointerFloat(HANDLE processHandle, int startAddress, int offsets[], int offsetCount) {
    if (startAddress == -1) {
        lastError = -1;
        return -1;
    }
	return ReadFloat(processHandle, GetPointerAddress(processHandle, startAddress, offsets, offsetCount));
}
char* Memory::ReadText(HANDLE processHandle, int address) {
    if (address == -1) {
        lastError = -1;
        return "";
    }
    char buffer = !0;
	char* stringToRead = new char[128];
    SIZE_T NumberOfBytesToRead = sizeof(buffer);
    SIZE_T NumberOfBytesActuallyRead;
	int i = 0;
	while (buffer != 0) {
		BOOL success = ReadProcessMemory(processHandle, (LPCVOID)address, &buffer, NumberOfBytesToRead, &NumberOfBytesActuallyRead);
        if (!success || NumberOfBytesActuallyRead != NumberOfBytesToRead) {
            lastError = -1;
            return "";
        }
        stringToRead[i] = buffer;
		i++;
		address++;
	}
    lastError = 0;
    return stringToRead;
}
char* Memory::ReadPointerText(HANDLE processHandle, int startAddress, int offsets[], int offsetCount) {
    if (startAddress == -1) {
        lastError = -1;
        return "";
    }
	return ReadText(processHandle, GetPointerAddress(processHandle, startAddress, offsets, offsetCount));
}
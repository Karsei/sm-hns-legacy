/*==================================================================
	
	------------------------------------
	-*- [Hide and Seek] API :: Timer -*-
	------------------------------------
	
	Filename: hns_timer_stocks.inc
	Author: Karsei
	Description: Timer Stocks API Library
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012 by Karsei All Right Reserved.
	
==================================================================*/

/**
 * 타이머가 현재 동작하는지 확인.
 * 
 * @param timer     타이머 핸들.
 */
stock bool:HNS_IsTimerRunning(Handle:timer)
{
    // 핸들이 비어있지 않다면 return true.
    return (timer != INVALID_HANDLE);
}

/**
 * KillTimer를 위한 Wrapper functions.
 * 타이머가 동작중이면 종료하고 그 타이머 핸들 변수를 초기화(리셋)한다.
 * 
 * @param timer     타이머 핸들.
 * @param kill      true로 설정하면 타이머 제거와 변수 리셋, false로 설정하면 변수만 리셋.
 *                  false는 타이머 콜백으로부터 호출 시 유용합니다. 왜냐하면 타이머가 이미 제거된 상태기 때문이지요.
 *                  (Using false is useful when calling from the timer callback, because the timer is already killed.)
 * 
 * @return          핸들이 비어있지 않았다면 true. 핸들 자체가 유효하지않았다면 false.
 */
stock bool:HNS_EndTimer(&Handle:timer, bool:kill = true)
{
    // 타이머가 동작중이라면 제거.
    if (HNS_IsTimerRunning(timer))
    {
        // Kill if caller says to.
        if (kill)
        {
            KillTimer(timer);
        }
        
        // 변수 초기화.
        timer = INVALID_HANDLE;
        
        return true;
    }
    
    // 변수 초기화.
    timer = INVALID_HANDLE;
    
    return false;
}

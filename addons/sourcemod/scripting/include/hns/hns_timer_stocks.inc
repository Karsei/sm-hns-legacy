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
 * Ÿ�̸Ӱ� ���� �����ϴ��� Ȯ��.
 * 
 * @param timer     Ÿ�̸� �ڵ�.
 */
stock bool:HNS_IsTimerRunning(Handle:timer)
{
    // �ڵ��� ������� �ʴٸ� return true.
    return (timer != INVALID_HANDLE);
}

/**
 * KillTimer�� ���� Wrapper functions.
 * Ÿ�̸Ӱ� �������̸� �����ϰ� �� Ÿ�̸� �ڵ� ������ �ʱ�ȭ(����)�Ѵ�.
 * 
 * @param timer     Ÿ�̸� �ڵ�.
 * @param kill      true�� �����ϸ� Ÿ�̸� ���ſ� ���� ����, false�� �����ϸ� ������ ����.
 *                  false�� Ÿ�̸� �ݹ����κ��� ȣ�� �� �����մϴ�. �ֳ��ϸ� Ÿ�̸Ӱ� �̹� ���ŵ� ���±� ����������.
 *                  (Using false is useful when calling from the timer callback, because the timer is already killed.)
 * 
 * @return          �ڵ��� ������� �ʾҴٸ� true. �ڵ� ��ü�� ��ȿ�����ʾҴٸ� false.
 */
stock bool:HNS_EndTimer(&Handle:timer, bool:kill = true)
{
    // Ÿ�̸Ӱ� �������̶�� ����.
    if (HNS_IsTimerRunning(timer))
    {
        // Kill if caller says to.
        if (kill)
        {
            KillTimer(timer);
        }
        
        // ���� �ʱ�ȭ.
        timer = INVALID_HANDLE;
        
        return true;
    }
    
    // ���� �ʱ�ȭ.
    timer = INVALID_HANDLE;
    
    return false;
}
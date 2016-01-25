%{
/*
This file is part of Reverse Notation Calc.

    Reverse Notation Calc is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

*/



#include "mystack.h"

#define TYPE_RANGE 9
#define TYPE_NUMBER 1

int int_value;
char buffer[255];

typedef enum {
    LexNumber=1001,
    LexPlus,
    LexMinus,
    LexDiv,
    LexMult,
    LexEntry,
    LexRange,
    LexEnd,
    LexUnknown,
} LexType;

my_stack stack;

int end_file;

%}

%s SKIPERROR

digit     [0-9]
number    {digit}+
range     \[{number}(\,{number})?\.\.\.{number}\]

%%

{range}     {
          fprintf(stderr, "found range\n");
          char *currentChar = yytext;
          currentChar++;
          memset(buffer,0,255);
          int stringSize = 0;
		    while (*currentChar != ']') {
		    buffer[stringSize]=*currentChar;
		    currentChar++;
		    stringSize++;
		  }
          return LexRange;  }    

{number}	{
		  int_value=atoi(yytext);
		  fprintf(stderr, "found %d\n", int_value);
		  return LexNumber; }
\?      {
          fprintf(stderr, "entry\n");
          return LexEntry; }
\+		{
		  fprintf(stderr, "plus\n");
		  return LexPlus; }
\-		{
		  fprintf(stderr, "minus\n");
		  return LexMinus; }
\/		{
		  fprintf(stderr, "div\n");
		  return LexDiv; }
\*		{
		  fprintf(stderr, "mult\n");
		  return LexMult; }
^[ \t]*\n	{
		  fprintf(stderr, "empty line\n");
		}
\n		{
		  fprintf(stderr, "CR\n");
		  return LexEnd; }
[ \t]		{ }
.		{ return LexUnknown; }

<SKIPERROR>[^\n]* {}
%%

int process_command(int token)
{
    fprintf(stderr, "token: %d\n", token);

    switch (token) {
    case LexNumber:  {
        my_stack_push(&stack, int_value);
        my_stack_push(&stack, TYPE_NUMBER);
        if (my_stack_is_full(&stack)) {
            return -1;
        }
        break; }
    case LexPlus: {
        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int type1=my_stack_pull(&stack);
        int a=my_stack_pull(&stack);

        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int type2=my_stack_pull(&stack);
        int b=my_stack_pull(&stack);

        my_stack_push(&stack, a+b);
        my_stack_push(&stack, TYPE_NUMBER);
        if (my_stack_is_full(&stack)) {
            return -1;
        }
        break;}
    case LexMinus: {
        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int type1=my_stack_pull(&stack);
        int a=my_stack_pull(&stack);

        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int type2=my_stack_pull(&stack);
        int b=my_stack_pull(&stack);

        my_stack_push(&stack, b-a);
        my_stack_push(&stack, TYPE_NUMBER);
        if (my_stack_is_full(&stack)) {
            return -1;
        }
        break;}
    case LexDiv: {
        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int type1=my_stack_pull(&stack);
        int a=my_stack_pull(&stack);

        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int type2=my_stack_pull(&stack);
        int b=my_stack_pull(&stack);

        my_stack_push(&stack, b/a);
        my_stack_push(&stack, TYPE_NUMBER);
        if (my_stack_is_full(&stack)) {
            return -1;
        }
        break;}
    case LexMult: {
        int a,b,lastElement1,lastElement2,step1,step2,firstElement1,firstElement2=0;
        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int type1=my_stack_pull(&stack);
        
        if (type1 == TYPE_NUMBER) {
            a=my_stack_pull(&stack);
        }
        else {
            if (type1 == TYPE_RANGE) {
                lastElement1 = my_stack_pull(&stack);
                step1 = my_stack_pull(&stack);
                firstElement1 = my_stack_pull(&stack);
            }
        }

        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        
        int type2=my_stack_pull(&stack);
        
        if (type2 == TYPE_NUMBER) {
            b=my_stack_pull(&stack);
        }
        else {
            if (type2 == TYPE_RANGE) {
                lastElement2 = my_stack_pull(&stack);
                step2 = my_stack_pull(&stack);
                firstElement2 = my_stack_pull(&stack);
            }
        }
        
        if ((type1 == TYPE_NUMBER) && (type2 == TYPE_NUMBER)) {
            my_stack_push(&stack, b*a);
            my_stack_push(&stack, TYPE_NUMBER);
        }
        
        if ((type1 == TYPE_NUMBER) && (type2 == TYPE_RANGE)) {
            my_stack_push(&stack, firstElement2*a);
            my_stack_push(&stack, step2);
            my_stack_push(&stack, lastElement2*a);
            my_stack_push(&stack, TYPE_RANGE);
        }
        
        if ((type1 == TYPE_RANGE) && (type2 == TYPE_NUMBER)) {
            my_stack_push(&stack, firstElement1*b);
            my_stack_push(&stack, step1);
            my_stack_push(&stack, lastElement1*b);
            my_stack_push(&stack, TYPE_RANGE);
        }
        
        if (my_stack_is_full(&stack)) {
            return -1;
        }
        break;}
        
    case LexEntry: {
        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        
        int type1=my_stack_pull(&stack);
        if ( type1 != TYPE_NUMBER) {
            return -1;
        }
        
        int myNumber = my_stack_pull(&stack);
        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        
        int type2=my_stack_pull(&stack);
        if (type2 != TYPE_RANGE) {
            return -1;
        }
        
        int lastElement = my_stack_pull(&stack);
        int step = my_stack_pull(&stack);
        int firstElement = my_stack_pull(&stack);
        
        int entry = 0;
        for (int i = firstElement; i <= lastElement; i+=step) {
            if (myNumber == i) {
                entry = 1;
            }
        }
        my_stack_push(&stack, entry);
        my_stack_push(&stack, TYPE_NUMBER);
        
        if (my_stack_is_full(&stack)) {
            return -1;
        }
        break;}
    
    case LexRange:  {
        char *currentChar = &buffer[0];
        char strFirstElement[20] = "";
        int i = 0;
        
        while ((*currentChar != '.') && (*currentChar != ',')) {
            strFirstElement[i] = *currentChar;
            currentChar++;
            i++;
        }
        int firstElement = atoi(strFirstElement);
        my_stack_push(&stack, firstElement);
        
        char strStep[20] = "";
        int step = 1;
        
        i = 0;
        
        if (*currentChar == ',') {
            currentChar++;
            while (*currentChar != '.') {
                strStep[i] = *currentChar;
                currentChar++;
                i++;
            }
            step = atoi(strStep);
        }
        my_stack_push(&stack, step);
        
        char strLastElement[20] = "";
        
        i = 0;
        currentChar = currentChar + 3;
        
        while (*currentChar != '\0') {
            strLastElement[i] = *currentChar;
            currentChar++;
            i++;
        }
        int lastElement = atoi(strLastElement);
        my_stack_push(&stack, lastElement);
        my_stack_push(&stack, TYPE_RANGE);
        
        
        break;}
    case LexEnd:
    case 0:
        return 0;
    case LexUnknown:
        return -1;

    }
    return 1;
}

int calc_line()
{
    int token = yylex();
    if (token == 0) {
        return 1;
    }

    while (1) {
        int cmd_res = process_command(token);
        if (cmd_res == 0) {
            break;
        }
        else if (cmd_res == -1) {
            fprintf(stderr, "Syntax error\n");
            return 0;
        }
        token = yylex();
    }

    if (my_stack_is_empty(&stack)) {
        fprintf(stderr, "Stack is empty but required value\n");
        return 0;
    }
    int type = my_stack_pull(&stack);
    if (type == TYPE_NUMBER) {
        int result = my_stack_pull(&stack);
        fprintf(yyout, "%d ", result);
    }
    
    if (type == TYPE_RANGE) {
        int lastElement = my_stack_pull(&stack);
        int step = my_stack_pull(&stack);
        int firstElement = my_stack_pull (&stack);
        fprintf(yyout, "range(%d,%d,%d) ", firstElement, step, lastElement);
    }

    if (!my_stack_is_empty(&stack)) {
        fprintf(stderr, "Stack not empty after calculation\n");
        return 0;
    }

    return 1;
}

void calc()
{
    while (!end_file) {
        fprintf(stderr, "parse line\n");
        if (calc_line() == 0) {
            printf("FAIL\n");
            BEGIN(SKIPERROR);
            yylex();
            BEGIN(INITIAL);
        }
        else {
            printf("OK\n");
        }
        fprintf(stderr, "line parsed\n");
    }
}

int main(void)
{
    my_stack_init(&stack, 100);
    end_file = 0;

    calc();

    my_stack_done(&stack);
    return 0;
}

int yywrap(void)
{
    end_file = 1;
    return 1;
}

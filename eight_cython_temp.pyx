# cython: language_level=3
from cpython.ref cimport PyObject
from libc.string import memcpy, malloc

import sys
from collections import deque
import copy

SIZE = 3
DEFAULT_EMPTY_INDEX = (SIZE + 1)*(SIZE/2)
FINAL = [list(range(i*SIZE, (i+1)*SIZE)) for i in range(SIZE)]

cdef struct BoardPosition:
    int row
    int column

cdef class State:

    cdef int **board
    cdef BoardPosition _zero_index

    @classmethod
    def from_file(cls, data):
        board = []
        for line in data.split('\n'):
            if not line:
                continue
            numbers = [int(x) if x != 'X' else 0 for x in line.split()]
            board.append(numbers)
        return cls(board)

    cdef void initialize(self, int **board, State parent):
        self.board = board
        self.parent = parent
        if self.parent is None:
            self.depth = 0
        else:
            self.depth = parent.depth + 1
        self._zero_index = BoardPosition(-1, -1)

    cdef BoardPosition zero_index(self):
        if self._zero_index.row != -1:
            return self._zero_index
        for i in range(SIZE):
            for j in range(SIZE):
                if self.board[i][j] == 0:
                    self._zero_index = (i,j)
                    return BoardPosition(row=i, column=j)
        raise ValueError("Invalid board")



    cdef PyObject *children(self):
        cdef int **new_board
        cdef State new_state
        cdef int row, column, index
        cdef BoardPosition zi = self.zero_index()
        possible_swaps = []
        #left
        # if zi.column > 0:
        #     possible_swaps.append((zi.row, zi.column - 1))
        # #right
        # if zi.column < 2:
        #     possible_swaps.append((zi.row, zi.column + 1))
        # #above
        # if zi.row > 0:
        #     possible_swaps.append((zi.row - 1, zi.column))
        # #below
        # if zi.row < 2:
        #     possible_swaps.append((zi.row + 1, zi.column))
        children = []
        for new_row, new_column in possible_swaps:
            new_board = <int **>malloc(sizeof(int**))
            for index in range(3):
                new_board[x] = malloc(3*sizeof(int))
                memcpy(new_board[x], self.board[x])
            new_board[new_row][new_column], new_board[zi.row][zi.column] = (new_board[zi.row][zi.column],
                                                                            new_board[new_row][new_column])
            new_state = State()
            new_state.initialize(new_board, self)
            children.append(new_state)
        return children


    @property
    def final(self):
        return self.board == FINAL


    def __eq__(self, other):
        return self.board == other.board

    def __repr__(self):
        return "< %r >" % self.sequence

    def __str__(self):
        parts = [' '.join(str(y) for y in x) for x in self.board]
        return "\n".join(parts)

    def __hash__(self):
        str_rep = '/'.join('/'.join(str(y) for y in x) for x in self.board)
        return hash(str_rep)


def search(node):
    queue = deque()
    queue.append(node)
    processed = set()
    while queue:
        current = queue.popleft()
        if current in processed:
            continue
        if current.final:
            return current
        processed.add(current)
        for child in current.children():
            queue.append(child)
    return None


if __name__ == "__main__":
    with open (sys.argv[1], 'r') as inp_file:
        data = inp_file.read()
    state = State.from_file(data)
    found = search(state)
    if found:
        node = found
        while node is not None:
            print(node)
            print('')
            node = node.parent
    else:
        print("Could not find solution")

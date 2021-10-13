// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Library is Ownable {
    
    struct Book {
        string name;
        uint8 copies;
        uint8 borrowedCopies;
        address[] borrowHistory;
    }
    
    Book[] public books;
    mapping(address => uint32[]) public ownerBorrowedBooks;
    
    function _getAvailableBooksCount() private view returns(uint) {
        uint availableBooksCount;
        for (uint i = 0; i < books.length; i++) {
          if (books[i].copies > books[i].borrowedCopies) {
            availableBooksCount++;
          }
        }
        return availableBooksCount;
    }
    
    function _isBorrowed(uint32 _bookId) private view returns(bool, uint) {
        bool isBorrowed = false;
        uint bookIndex;
        for (uint i = 0; i < ownerBorrowedBooks[msg.sender].length; i++) {
          if (ownerBorrowedBooks[msg.sender][i] == _bookId) {
            isBorrowed = true;
            bookIndex = i;
            break;
          }
        }
        return (isBorrowed, bookIndex);
    }
    
    function addNewBook(string memory name, uint8 copies) external onlyOwner {
        books.push(Book(name, copies, 0, new address[](0)));
    }
    
    function getAvailableBooks() external view returns(uint[] memory) {
        uint[] memory availableBooks = new uint[](_getAvailableBooksCount());
        uint counter = 0;
        for (uint i = 0; i < books.length; i++) {
          if (books[i].copies > books[i].borrowedCopies) {
            availableBooks[counter] = i;
            counter++;
          }
        }
        return availableBooks;
    }
    
    function borrowBook(uint32 _bookId) external {
        require(books[_bookId].copies > books[_bookId].borrowedCopies);
        (bool isBorrowed,) = _isBorrowed(_bookId);
        require(!isBorrowed);

        ownerBorrowedBooks[msg.sender].push(_bookId);
        books[_bookId].borrowedCopies++;
        books[_bookId].borrowHistory.push(msg.sender);
    }
    
    function returnBook(uint32 _bookId) external {
        require(books[_bookId].borrowedCopies != 0);
        (bool isBorrowed, uint bookIndex) = _isBorrowed(_bookId);
        require(isBorrowed);

        // Shift array to keep order of borrowed books.
        for (uint i = bookIndex; i < ownerBorrowedBooks[msg.sender].length - 1; i++) {
          ownerBorrowedBooks[msg.sender][i] = ownerBorrowedBooks[msg.sender][i + 1];
        }
        // Delete empty value at the end of the array.
        uint32[] memory newArray = new uint32[](ownerBorrowedBooks[msg.sender].length - 1);
        for (uint i = 0; i < newArray.length; i++) {
          newArray[i] = ownerBorrowedBooks[msg.sender][i];
        }
        ownerBorrowedBooks[msg.sender] = newArray;
        books[_bookId].borrowedCopies--;
    }
}
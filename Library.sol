// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Library is Ownable {
    
    struct Book {
        string name;
        uint8 copies;
        uint8 borrowedCopies;
    }
    
    Book[] public books;
    mapping(uint32 => address[]) public bookToOwners;
    mapping(address => uint32[]) public ownerToBooks;
    
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
        for (uint i = 0; i < ownerToBooks[msg.sender].length; i++) {
          if (ownerToBooks[msg.sender][i] == _bookId) {
            isBorrowed = true;
            bookIndex = i;
            break;
          }
        }
        return (isBorrowed, bookIndex);
    }
    
    function addNewBook(string memory name, uint8 copies) external onlyOwner {
        books.push(Book(name, copies, 0));
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

        ownerToBooks[msg.sender].push(_bookId);
        books[_bookId].borrowedCopies++;
        bookToOwners[_bookId].push(msg.sender);
    }
    
    function returnBook(uint32 _bookId) external {
        require(books[_bookId].borrowedCopies != 0);
        (bool isBorrowed, uint bookIndex) = _isBorrowed(_bookId);
        require(isBorrowed);

        // Shift array to keep order of borrowed books.
        for (uint i = bookIndex; i < ownerToBooks[msg.sender].length - 1; i++) {
          ownerToBooks[msg.sender][i] = ownerToBooks[msg.sender][i + 1];
        }
        // Delete empty value at the end of the array.
        uint32[] memory newArray = new uint32[](ownerToBooks[msg.sender].length - 1);
        for (uint i = 0; i < newArray.length; i++) {
          newArray[i] = ownerToBooks[msg.sender][i];
        }
        ownerToBooks[msg.sender] = newArray;
        books[_bookId].borrowedCopies--;
    }
}
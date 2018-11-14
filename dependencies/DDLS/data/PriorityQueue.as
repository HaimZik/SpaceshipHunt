package DDLS.data
{
	
	public class PriorityQueue
	{
		protected var scoreF:Array;
		protected var _queue:Vector.<int>;
		protected var _length:int = 0;
		protected var itemIndex:Vector.<int>;
		
		/**
		 * This is an improved Priority Queue data type implementation that can be used to sort any object type.
		 * It uses a technique called a binary heap.
		 *
		 * For more on binary heaps see: http://en.wikipedia.org/wiki/Binary_heap
		 *
		 * @param criteria The criteria by which to sort the objects. This should be a property of the objects you're sorting.
		 **/
		public function PriorityQueue(scoreF:Array, largestID:int)
		{
			this.scoreF = scoreF;
			for (var i:int = scoreF.length; i < largestID; i++)
			{
				this.scoreF[i] = 0;
			}
			itemIndex = new Vector.<int>(largestID);
			_queue = new Vector.<int>();
		}
		
		/**
		 * Inserts the value into the heap and sorts it.
		 *
		 * @param value The object to insert into the heap.
		 **/
		public function insert(itemID:int):void
		{
			_queue[_length] = itemID;
			bubbleUp(_length++);
		}
		
		/**
		 * Returns the length of the heap.
		 * @return the length of the heap
		 **/
		public function get length():int
		{
			return _length;
		}
		
		public function reset(largestID:int):void
		{
			for (var i:int = scoreF.length; i < largestID; i++)
			{
				scoreF[i] = 0;
			}
			itemIndex.length = largestID;
			_queue.length = 0;
			_length = 0;
		}
		
		/**
		 * Peeks at the highest priority element.
		 * @return the highest priority element
		 **/
		public function getHighestPriorityItem():int
		{
			return _queue[0];
		}
		
		/**
		 * Removes and returns the highest priority element from the queue.
		 * @return the highest priority item id
		 **/
		public function shiftHighestPriorityItem():int
		{
			//if (_length < 0)
			//{
			//throw new Error("There are no more elements in your priority queue.");
			//}
			var oldRoot:int = _queue[0];
			var newRoot:int = _queue.pop();
			if (--_length != 0)
			{
				_queue[0] = newRoot;
				itemIndex[newRoot] = 0;
				swapUntilQueueIsCorrect(0);
			}
			return oldRoot;
		}
		
		public function decreaseHeuristics(itemID:int):void
		{
			var index:int = itemIndex[itemID];
			bubbleUp(index);
		}
		
		private function bubbleUp(index:int):void
		{
			if (index == 0)
			{
				return;
			}
			
			var parent:int = getParentOf(index);
			if (evaluate(index, parent))
			{
				swap(index, parent);
				bubbleUp(parent);
			}
		}
		
		private function swapUntilQueueIsCorrect(index:uint):void
		{
			var left:int = getLeftOf(index);
			var right:int = getRightOf(index);
			
			if (evaluate(left, index))
			{
				swap(index, left);
				swapUntilQueueIsCorrect(left);
			}
			else if (evaluate(right, index))
			{
				swap(index, right);
				swapUntilQueueIsCorrect(right);
			}
			else if (index != 0)
			{
				swapUntilQueueIsCorrect(0);
			}
		}
		
		private function swap(self:int, target:int):void
		{
			var placeHolder:int = _queue[self];
			_queue[self] = _queue[target];
			_queue[target] = placeHolder;
			itemIndex[_queue[target]] = self;
			itemIndex[placeHolder] = target;
		}
		
		/**
		 * Helpers
		 */
		private function evaluate(self:int, target:int):Boolean
		{
			//if (_isMax)
			//{
			return self < _length && scoreF[_queue[self]] < scoreF[_queue[target]];
			//}
			//else
			//{
			//if (_queue[self][_criteria] < _queue[target][_criteria])
			//{
			//return true;
			//}
			//else
			//{
			//return false;
			//}
			//}
		}
		
		private function getParentOf(index:int):int
		{
			return (index - 1) >> 1;
		}
		
		private function getLeftOf(index:uint):uint
		{
			return (index << 1) + 1;
		}
		
		private function getRightOf(index:uint):uint
		{
			return (index << 1) + 2;
		}
	}
}
/*
Copyright (c) 2012 Josh Tynjala

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/
package feathers.motion.transitions
{
	import feathers.controls.IScreen;
	import feathers.controls.ScreenNavigator;

	import flash.utils.getQualifiedClassName;

	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.DisplayObject;

	/**
	 * A transition for <code>ScreenNavigator</code> that slides out the old
	 * screen and slides in the new screen at the same time. The slide starts
	 * from the right or left, depending on if the manager determines if the
	 * transition is a push or a pop.
	 */
	public class ScreenSlidingStackTransitionManager
	{
		/**
		 * Constructor.
		 */
		public function ScreenSlidingStackTransitionManager(navigator:ScreenNavigator, quickStack:Class = null)
		{
			if(!navigator)
			{
				throw new ArgumentError("ScreenNavigator cannot be null.");
			}
			this._navigator = navigator;
			if(quickStack)
			{
				this._stack.push(quickStack);
			}
			this._navigator.transition = this.onTransition;
		}
		
		private var _navigator:ScreenNavigator;
		private var _stack:Vector.<String> = new <String>[];
		private var _activeTransition:Tween;
		private var _savedOtherTarget:DisplayObject;
		private var _savedCompleteHandler:Function;
		
		/**
		 * The duration of the transition, in seconds.
		 */
		public var duration:Number = 0.25;

		/**
		 * A delay before the transition starts, measured in seconds. This may
		 * be required on low-end systems that will slow down for a short time
		 * after heavy texture uploads.
		 */
		public var delay:Number = 0.1;
		
		/**
		 * The easing function to use.
		 */
		public var ease:Object = Transitions.EASE_OUT;
		
		/**
		 * Removes all saved classes from the stack that are used to determine
		 * which side of the <code>ScreenNavigator</code> the new screen will
		 * slide in from.
		 */
		public function clearStack():void
		{
			this._stack.length = 0;
		}
		
		/**
		 * @private
		 */
		private function onTransition(oldScreen:DisplayObject, newScreen:DisplayObject, onComplete:Function):void
		{
			if(!oldScreen || !newScreen)
			{
				if(newScreen)
				{
					newScreen.x = 0;
				}
				if(oldScreen)
				{
					oldScreen.x = 0;
				}
				onComplete();
				return;
			}
			
			if(this._activeTransition)
			{
				this._savedOtherTarget = null;
				Starling.juggler.remove(this._activeTransition);
				this._activeTransition = null;
			}
			
			this._savedCompleteHandler = onComplete;

			var newScreenClassAndID:String = getQualifiedClassName(newScreen);
			if(newScreen is IScreen)
			{
				newScreenClassAndID += "~" + IScreen(newScreen).screenID;
			}
			var stackIndex:int = this._stack.indexOf(newScreenClassAndID);
			var activeTransition_onUpdate:Function;
			if(stackIndex < 0)
			{
				var oldScreenClassAndID:String = getQualifiedClassName(oldScreen);
				if(oldScreen is IScreen)
				{
					oldScreenClassAndID += "~" + IScreen(oldScreen).screenID;
				}
				this._stack.push(oldScreenClassAndID);
				oldScreen.x = 0;
				newScreen.x = this._navigator.width;
				activeTransition_onUpdate = this.activeTransitionPush_onUpdate;
			}
			else
			{
				this._stack.length = stackIndex;
				oldScreen.x = 0;
				newScreen.x = -this._navigator.width;
				activeTransition_onUpdate = this.activeTransitionPop_onUpdate;
			}
			this._savedOtherTarget = oldScreen;
			this._activeTransition = new Tween(newScreen, this.duration, this.ease);
			this._activeTransition.animate("x", 0);
			this._activeTransition.delay = this.delay;
			this._activeTransition.onUpdate = activeTransition_onUpdate;
			this._activeTransition.onComplete = activeTransition_onComplete;
			Starling.juggler.add(this._activeTransition);
		}
		
		/**
		 * @private
		 */
		private function activeTransitionPush_onUpdate():void
		{
			if(this._savedOtherTarget)
			{
				const newScreen:DisplayObject = DisplayObject(this._activeTransition.target);
				this._savedOtherTarget.x = newScreen.x - this._navigator.width;
			}
		}
		
		/**
		 * @private
		 */
		private function activeTransitionPop_onUpdate():void
		{
			if(this._savedOtherTarget)
			{
				const newScreen:DisplayObject = DisplayObject(this._activeTransition.target);
				this._savedOtherTarget.x = newScreen.x + this._navigator.width;
			}
		}
		
		/**
		 * @private
		 */
		private function activeTransition_onComplete():void
		{
			this._activeTransition = null;
			this._savedOtherTarget = null;
			if(this._savedCompleteHandler != null)
			{
				this._savedCompleteHandler();
			}
		}
	}
}